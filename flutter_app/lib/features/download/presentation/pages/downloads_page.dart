import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/download_service.dart';

/// Downloads manager fed by real downloader records (Hive + flutter_downloader).
/// Completed files play inside the app with the built-in offline player.
class DownloadsPage extends ConsumerStatefulWidget {
  const DownloadsPage({super.key});

  @override
  ConsumerState<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends ConsumerState<DownloadsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refresh();
  }

  Future<void> _refresh() async {
    final service = ref.read(downloadServiceProvider);
    await service.refreshFromDownloader();
    if (mounted) setState(() => _records = service.getRecords());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filter(List<String> statuses) {
    return _records.where((r) => statuses.contains(r['status'])).toList();
  }

  void _playDownloaded(Map<String, dynamic> record) {
    final filePath = record['filePath']?.toString() ?? '';
    if (filePath.isEmpty || !File(filePath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File not found on device')),
      );
      return;
    }
    final file = Uri.encodeComponent(filePath);
    final title = Uri.encodeComponent(record['animeTitle']?.toString() ?? '');
    final ep = record['episodeNumber'] ?? 1;
    context.push('/player/${record['episodeId']}?episode=$ep&file=$file&title=$title');
  }

  String _formatSize(dynamic bytes) {
    final b = (bytes as num?)?.toInt() ?? 0;
    if (b <= 0) return '';
    if (b >= 1 << 30) return '${(b / (1 << 30)).toStringAsFixed(2)} GB';
    return '${(b / (1 << 20)).toStringAsFixed(0)} MB';
  }

  Future<void> _confirmDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all downloads?'),
        content: const Text('This removes every download record and its file.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = ref.read(downloadServiceProvider);
      for (final r in List.of(_records)) {
        await service.deleteRecord(r['taskId'].toString());
      }
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(downloadServiceProvider);
    final downloading = _filter(['enqueued', 'running', 'paused']);
    final completed = _filter(['complete']);
    final failed = _filter(['failed', 'canceled', 'undefined']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete all',
            onPressed: _records.isEmpty ? null : _confirmDeleteAll,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.folder_open_rounded,
                        size: 14, color: AppTheme.textHint),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        service.configuredPath,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textHint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondary,
                tabs: [
                  Tab(text: 'Active (${downloading.length})'),
                  Tab(text: 'Completed (${completed.length})'),
                  Tab(text: 'Failed (${failed.length})'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(
            items: downloading,
            emptyIcon: Icons.downloading_rounded,
            emptyText: 'No active downloads',
            itemBuilder: _buildDownloadingTile,
          ),
          _buildList(
            items: completed,
            emptyIcon: Icons.offline_pin_outlined,
            emptyText:
                'Nothing downloaded yet.\nEpisodes you download will play here, offline.',
            itemBuilder: _buildCompletedTile,
          ),
          _buildList(
            items: failed,
            emptyIcon: Icons.error_outline_rounded,
            emptyText: 'No failed downloads',
            itemBuilder: _buildFailedTile,
          ),
        ],
      ),
    );
  }

  Widget _buildList({
    required List<Map<String, dynamic>> items,
    required IconData emptyIcon,
    required String emptyText,
    required Widget Function(Map<String, dynamic>, int) itemBuilder,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon,
                size: 72, color: AppTheme.textHint.withOpacity(0.35)),
            const SizedBox(height: 14),
            Text(
              emptyText,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textHint, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: _refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) =>
            itemBuilder(items[index], index),
      ),
    );
  }

  Widget _thumbnailPlaceholder({IconData icon = Icons.movie, double width = 80, double height = 55}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(icon, color: AppTheme.textHint),
      ),
    );
  }

  Widget _titleBlock(Map<String, dynamic> record, {String? subtitle}) {
    final title = record['animeTitle']?.toString() ?? 'Episode';
    final episode = record['episodeNumber'] ?? '?';
    final quality = record['quality']?.toString() ?? '';
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle ?? 'Episode $episode${quality.isNotEmpty ? ' • $quality' : ''}',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadingTile(Map<String, dynamic> record, int index) {
    final progress = ((record['progress'] as num?) ?? 0) / 100.0;
    final isPaused = record['status'] == 'paused';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _thumbnailPlaceholder(),
                const SizedBox(width: 14),
                _titleBlock(record,
                    subtitle:
                        'Episode ${record['episodeNumber'] ?? '?'} • ${record['quality'] ?? ''}'),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearPercentIndicator(
              padding: EdgeInsets.zero,
              lineHeight: 6,
              percent: progress.clamp(0.0, 1.0),
              backgroundColor: AppTheme.textHint.withOpacity(0.2),
              progressColor: AppTheme.primaryColor,
              barRadius: const Radius.circular(3),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  isPaused
                      ? Icons.pause_circle_outline_rounded
                      : Icons.downloading_rounded,
                  size: 15,
                  color: isPaused
                      ? AppTheme.warningColor
                      : AppTheme.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  isPaused ? 'Paused' : 'Downloading…',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),

                // Pause / Resume
                _actionButton(
                  icon: isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  tooltip: isPaused ? 'Resume' : 'Pause',
                  color: AppTheme.primaryColor,
                  onPressed: () async {
                    final service = ref.read(downloadServiceProvider);
                    if (isPaused) {
                      await service.resumeTask(record['taskId'].toString());
                    } else {
                      await service.pauseTask(record['taskId'].toString());
                    }
                    await _refresh();
                  },
                ),
                const SizedBox(width: 8),

                // Cancel
                _actionButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Cancel',
                  color: AppTheme.errorColor,
                  onPressed: () async {
                    await ref
                        .read(downloadServiceProvider)
                        .cancelTask(record['taskId'].toString());
                    await _refresh();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: index * 80),
        );
  }

  /// Small circular action used for pause / resume / cancel.
  Widget _actionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(0.12),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 19, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedTile(Map<String, dynamic> record, int index) {
    final filePath = record['filePath']?.toString() ?? '';
    final exists = filePath.isNotEmpty && File(filePath).existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _playDownloaded(record),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _thumbnailPlaceholder(icon: Icons.offline_pin_outlined),
              const SizedBox(width: 14),
              _titleBlock(
                record,
                subtitle: exists
                    ? 'Episode ${record['episodeNumber'] ?? '?'} • ${record['quality'] ?? ''}'
                    : 'File missing on device',
              ),

              // Play button — opens the built-in offline player
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (exists ? AppTheme.primaryColor : AppTheme.textHint)
                      .withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: exists ? AppTheme.primaryColor : AppTheme.textHint,
                  size: 22,
                ),
              ),

              // Delete
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppTheme.textHint, size: 20),
                onPressed: () async {
                  await ref
                      .read(downloadServiceProvider)
                      .deleteRecord(record['taskId'].toString());
                  await _refresh();
                },
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: index * 80),
        );
  }

  Widget _buildFailedTile(Map<String, dynamic> record, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _thumbnailPlaceholder(icon: Icons.error_outline_rounded),
            const SizedBox(width: 14),
            _titleBlock(
              record,
              subtitle: record['status'] == 'canceled'
                  ? 'Download cancelled'
                  : 'Download failed',
            ),
            TextButton.icon(
              onPressed: () async {
                await ref
                    .read(downloadServiceProvider)
                    .retryTask(record['taskId'].toString());
                await _refresh();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: index * 80),
        );
  }
}
