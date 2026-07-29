import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

/// Where episode files are stored. Third-party download links
/// (Mega, GDrive, Terabox, Telegram, …) are fetched straight to the
/// device — the default is a "DHS Anime" folder on internal storage.
enum DownloadLocationType { internalRoot, downloadsFolder, appPrivate }

class DownloadLocationOption {
  final DownloadLocationType type;
  final String name;
  final String description;

  const DownloadLocationOption({
    required this.type,
    required this.name,
    required this.description,
  });
}

const kDownloadLocationOptions = <DownloadLocationOption>[
  DownloadLocationOption(
    type: DownloadLocationType.internalRoot,
    name: 'Internal Storage / DHS Anime',
    description: 'Visible in any file manager — recommended (default)',
  ),
  DownloadLocationOption(
    type: DownloadLocationType.downloadsFolder,
    name: 'Downloads / DHS Anime',
    description: 'Inside the system Downloads folder',
  ),
  DownloadLocationOption(
    type: DownloadLocationType.appPrivate,
    name: 'App Private Folder',
    description: 'Only this app can see it. Deleted on uninstall. '
        'No storage permission needed.',
  ),
];

class DownloadService {
  Box get _downloadsBox => Hive.box(AppConstants.downloadsBox);
  Box get _settingsBox => Hive.box(AppConstants.settingsBox);

  // ---------------------------------------------------------------------------
  // Location management
  // ---------------------------------------------------------------------------

  DownloadLocationType get selectedLocationType {
    final saved = _settingsBox.get(
      AppConstants.downloadLocationNameKey,
      defaultValue: DownloadLocationType.internalRoot.name,
    );
    return DownloadLocationType.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => DownloadLocationType.internalRoot,
    );
  }

  /// Absolute path currently used for new downloads. Defaults to
  /// `/storage/emulated/0/DHS Anime` (created automatically).
  String get configuredPath =>
      _settingsBox.get(AppConstants.downloadPathKey,
          defaultValue: AppConstants.defaultDownloadDir)
      as String;

  Future<void> selectLocation(DownloadLocationType type) async {
    await _settingsBox.put(AppConstants.downloadLocationNameKey, type.name);
    switch (type) {
      case DownloadLocationType.internalRoot:
        await _settingsBox.put(
            AppConstants.downloadPathKey, AppConstants.defaultDownloadDir);
        break;
      case DownloadLocationType.downloadsFolder:
        await _settingsBox.put(AppConstants.downloadPathKey,
            AppConstants.downloadFolderInDownloads);
        break;
      case DownloadLocationType.appPrivate:
        final dir = await getExternalStorageDirectory();
        final path =
            '${dir?.path ?? '/storage/emulated/0/Android/data/app/files'}/${AppConstants.appFolderName}';
        await _settingsBox.put(AppConstants.downloadPathKey, path);
        break;
    }
    // Create immediately so the folder shows up in file managers right away
    await ensureDownloadFolder();
  }

  /// Makes sure the "DHS Anime" folder (or the user-chosen one) exists,
  /// requesting storage permissions when necessary. Falls back to the
  /// app-private directory if public storage is not writable.
  Future<String> ensureDownloadFolder() async {
    var path = configuredPath;
    final isPrivatePath = selectedLocationType == DownloadLocationType.appPrivate;

    if (!isPrivatePath && Platform.isAndroid) {
      final granted = await requestStoragePermission();
      if (!granted) {
        // Degrade gracefully to the private folder
        final dir = await getExternalStorageDirectory();
        path = '${dir?.path ?? ''}/${AppConstants.appFolderName}';
      }
    }

    try {
      final directory = Directory(path);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    } catch (_) {
      // Last-resort fallback
      final dir = await getApplicationDocumentsDirectory();
      path = '${dir.path}/${AppConstants.appFolderName}';
      final directory = Directory(path);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }
    return path;
  }

  /// Storage permission strategy per Android version:
  ///  • API ≤ 29  → READ/WRITE_EXTERNAL_STORAGE
  ///  • API ≥ 30  → MANAGE_EXTERNAL_STORAGE (for writing to public root)
  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    var sdkInt = 30;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      sdkInt = info.version.sdkInt;
    } catch (_) {}

    if (sdkInt >= 30) {
      final status = await Permission.manageExternalStorage.status;
      if (status.isGranted) return true;
      final result = await Permission.manageExternalStorage.request();
      return result.isGranted;
    }

    final status = await Permission.storage.status;
    if (status.isGranted) return true;
    final result = await Permission.storage.request();
    return result.isGranted;
  }

  /// True when the app can currently write to the configured location
  /// (used by the Settings → Storage Permission row).
  Future<bool> hasStorageAccess() async {
    if (selectedLocationType == DownloadLocationType.appPrivate) return true;
    if (!Platform.isAndroid) return true;

    var sdkInt = 30;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      sdkInt = info.version.sdkInt;
    } catch (_) {}

    if (sdkInt >= 30) {
      return (await Permission.manageExternalStorage.status).isGranted;
    }
    return (await Permission.storage.status).isGranted;
  }

  // ---------------------------------------------------------------------------
  // Enqueueing downloads
  // ---------------------------------------------------------------------------

  /// Enqueue an episode download from a third-party link.
  /// Returns the downloader task id, or null on failure.
  Future<String?> enqueueEpisodeDownload({
    required String episodeId,
    required String animeTitle,
    required int episodeNumber,
    required String quality,
    required String url,
    required String host,
  }) async {
    final savedDir = await ensureDownloadFolder();
    final fileName = _buildFileName(
      animeTitle: animeTitle,
      episodeNumber: episodeNumber,
      quality: quality,
    );

    final taskId = await FlutterDownloader.enqueue(
      url: url,
      savedDir: savedDir,
      fileName: fileName,
      showNotification: true,
      openFileFromNotification: true,
      saveInPublicStorage: selectedLocationType != DownloadLocationType.appPrivate,
    );

    if (taskId != null) {
      await _downloadsBox.put(taskId, {
        'taskId': taskId,
        'episodeId': episodeId,
        'animeTitle': animeTitle,
        'episodeNumber': episodeNumber,
        'quality': quality,
        'host': host,
        'url': url,
        'fileName': fileName,
        'filePath': '$savedDir/$fileName',
        'status': 'enqueued',
        'progress': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
    return taskId;
  }

  String _buildFileName({
    required String animeTitle,
    required int episodeNumber,
    required String quality,
  }) {
    final safeTitle = animeTitle
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .trim();
    final ep = episodeNumber.toString().padLeft(2, '0');
    return '$safeTitle - E$ep [$quality].mp4';
  }

  // ---------------------------------------------------------------------------
  // Records (drives the Downloads page + offline player)
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> getRecords() {
    final list = _downloadsBox.values
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    list.sort((a, b) =>
        (b['createdAt'] ?? '').toString().compareTo((a['createdAt'] ?? '').toString()));
    return list;
  }

  /// Completed downloads whose file still exists — playable in the
  /// built-in player.
  List<Map<String, dynamic>> getPlayableRecords() {
    return getRecords().where((r) {
      if (r['status'] != 'complete') return false;
      final path = r['filePath']?.toString() ?? '';
      return path.isNotEmpty && File(path).existsSync();
    }).toList();
  }

  Map<String, dynamic>? findByEpisode(String episodeId) {
    for (final r in getPlayableRecords()) {
      if (r['episodeId'] == episodeId) return r;
    }
    return null;
  }

  /// Sync Hive records with the real downloader task states.
  Future<void> refreshFromDownloader() async {
    List<DownloadTask>? tasks;
    try {
      tasks = await FlutterDownloader.loadTasks();
    } catch (_) {
      return;
    }
    if (tasks == null) return;

    for (final task in tasks) {
      final record = _downloadsBox.get(task.taskId);
      if (record is! Map) continue;

      final updated = Map<String, dynamic>.from(record);
      updated['progress'] = task.progress;
      updated['status'] = switch (task.status) {
        DownloadTaskStatus.undefined => 'undefined',
        DownloadTaskStatus.enqueued => 'enqueued',
        DownloadTaskStatus.running => 'running',
        DownloadTaskStatus.complete => 'complete',
        DownloadTaskStatus.failed => 'failed',
        DownloadTaskStatus.canceled => 'canceled',
        DownloadTaskStatus.paused => 'paused',
      };
      await _downloadsBox.put(task.taskId, updated);
    }
  }

  Future<void> deleteRecord(String taskId, {bool deleteFile = true}) async {
    final record = _downloadsBox.get(taskId);
    if (record is Map && deleteFile) {
      final path = record['filePath']?.toString() ?? '';
      if (path.isNotEmpty) {
        try {
          final file = File(path);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
    }
    try {
      await FlutterDownloader.remove(taskId: taskId, shouldDeleteContent: deleteFile);
    } catch (_) {}
    await _downloadsBox.delete(taskId);
  }

  Future<void> cancelTask(String taskId) async {
    try {
      await FlutterDownloader.cancel(taskId: taskId);
    } catch (_) {}
    final record = _downloadsBox.get(taskId);
    if (record is Map) {
      final updated = Map<String, dynamic>.from(record);
      updated['status'] = 'canceled';
      await _downloadsBox.put(taskId, updated);
    }
  }

  Future<void> retryTask(String taskId) async {
    String? newId;
    try {
      newId = await FlutterDownloader.retry(taskId: taskId);
    } catch (_) {}
    if (newId != null) {
      final record = _downloadsBox.get(taskId);
      if (record is Map) {
        final updated = Map<String, dynamic>.from(record);
        updated['taskId'] = newId;
        updated['status'] = 'enqueued';
        updated['progress'] = 0;
        await _downloadsBox.delete(taskId);
        await _downloadsBox.put(newId, updated);
      }
    }
  }

  /// Total bytes used by completed downloads (best effort).
  Future<int> usedStorageBytes() async {
    var total = 0;
    for (final r in getPlayableRecords()) {
      try {
        total += await File(r['filePath'].toString()).length();
      } catch (_) {}
    }
    return total;
  }

  // ---------------------------------------------------------------------------
  // Settings → Download Location picker
  // ---------------------------------------------------------------------------

  Future<DownloadLocationType?> showLocationPicker(BuildContext context) {
    final current = selectedLocationType;
    return showModalBottomSheet<DownloadLocationType>(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Download Location',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Episodes are saved on your device and played offline in the app.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textHint),
                ),
                const SizedBox(height: 16),
                ...kDownloadLocationOptions.map((option) {
                  final isSelected = option.type == current;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withOpacity(0.12)
                          : AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        switch (option.type) {
                          DownloadLocationType.internalRoot =>
                            Icons.phone_android_rounded,
                          DownloadLocationType.downloadsFolder =>
                            Icons.folder_copy_outlined,
                          DownloadLocationType.appPrivate =>
                            Icons.lock_outline_rounded,
                        },
                        color: AppTheme.primaryColor,
                      ),
                      title: Text(
                        option.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        option.description,
                        style: const TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 12,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: AppTheme.primaryColor)
                          : null,
                      onTap: () => Navigator.pop(sheetContext, option.type),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

final downloadServiceProvider =
    Provider<DownloadService>((ref) => DownloadService());
