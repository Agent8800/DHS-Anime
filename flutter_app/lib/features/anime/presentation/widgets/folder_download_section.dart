import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../config/api_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../download/data/download_service.dart';
import '../../../download/presentation/widgets/download_links_sheet.dart';

/// Episode downloads, grouped folder-wise (e.g. "Season 1 • Hindi 1080p").
///
///  • Every single episode row has its own download button (opens the
///    mirror-links sheet).
///  • Every folder header has a "download all" button that queues the
///    first available mirror of each episode in that folder.
///
/// The section talks to the real API and degrades to demo folders when
/// the backend is unreachable so the layout stays previewable.
class FolderDownloadSection extends ConsumerStatefulWidget {
  final String animeId;
  final String animeTitle;

  const FolderDownloadSection({
    super.key,
    required this.animeId,
    required this.animeTitle,
  });

  @override
  ConsumerState<FolderDownloadSection> createState() =>
      _FolderDownloadSectionState();
}

class _FolderData {
  final String id;
  final String name;
  final int episodeCount;
  final String quality;

  const _FolderData({
    required this.id,
    required this.name,
    required this.episodeCount,
    required this.quality,
  });
}

class _EpisodeData {
  final String id;
  final int number;
  final String title;

  const _EpisodeData({
    required this.id,
    required this.number,
    required this.title,
  });
}

class _FolderDownloadSectionState
    extends ConsumerState<FolderDownloadSection> {
  bool _foldersMode = true;
  bool _loading = true;
  List<_FolderData> _folders = [];
  final Map<String, List<_EpisodeData>> _episodesByFolder = {};
  final Set<String> _loadingFolders = {};
  String? _expandedFolderId;

  // Bulk queue state
  String? _bulkFolderId;
  int _bulkDone = 0;
  int _bulkTotal = 0;

  bool get _isBulkRunning => _bulkFolderId != null;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<Dio> _dio() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: AppConstants.tokenKey);
    return Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(milliseconds: 8000),
      receiveTimeout: const Duration(milliseconds: 8000),
      headers: token != null ? {'Authorization': 'Bearer $token'} : null,
    ));
  }

  Future<void> _loadFolders() async {
    try {
      final dio = await _dio();
      final response = await dio.get('${ApiConfig.anime}/${widget.animeId}');
      final data = response.data['data'];
      final List raw = data is Map ? (data['folders'] as List? ?? []) : [];
      if (!mounted) return;
      setState(() {
        _folders = raw.map((f) {
          final map = Map<String, dynamic>.from(f as Map);
          return _FolderData(
            id: (map['_id'] ?? map['id'] ?? '').toString(),
            name: (map['name'] ?? 'Episodes').toString(),
            episodeCount: (map['episodeCount'] as num?)?.toInt() ?? 0,
            quality: (map['quality'] ?? '1080p').toString(),
          );
        }).toList();
        _loading = false;
        if (_folders.isNotEmpty) _expandedFolderId = _folders.first.id;
      });
      if (_folders.isNotEmpty) _loadEpisodes(_folders.first);
    } catch (_) {
      if (!mounted) return;
      // Demo fallback — keeps the screen previewable without a backend.
      setState(() {
        _folders = const [
          _FolderData(
            id: 'demo_s1_1080',
            name: 'Season 1 • Hindi 1080p',
            episodeCount: 26,
            quality: '1080p',
          ),
          _FolderData(
            id: 'demo_s1_720',
            name: 'Season 1 • Hindi 720p',
            episodeCount: 26,
            quality: '720p',
          ),
          _FolderData(
            id: 'demo_s2',
            name: 'Season 2 • Hindi 1080p',
            episodeCount: 12,
            quality: '1080p',
          ),
        ];
        _loading = false;
        _expandedFolderId = 'demo_s1_1080';
      });
    }
  }

  List<_EpisodeData> _demoEpisodes(_FolderData folder) {
    return List.generate(
      folder.episodeCount,
      (i) => _EpisodeData(
        id: '${folder.id}_ep_${i + 1}',
        number: i + 1,
        title: '',
      ),
    );
  }

  Future<void> _loadEpisodes(_FolderData folder) async {
    if (_episodesByFolder.containsKey(folder.id) ||
        _loadingFolders.contains(folder.id)) {
      return;
    }
    _loadingFolders.add(folder.id);
    try {
      final dio = await _dio();
      final response = await dio.get(
        '${ApiConfig.episodes}/folder/${folder.id}',
        queryParameters: {'limit': folder.episodeCount > 0 ? folder.episodeCount : 100},
      );
      final data = response.data['data'];
      final List raw =
          data is Map ? (data['episodes'] as List? ?? []) : (data as List? ?? []);
      if (!mounted) return;
      setState(() {
        _episodesByFolder[folder.id] = raw.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          return _EpisodeData(
            id: (map['_id'] ?? map['id'] ?? '').toString(),
            number: (map['episodeNumber'] as num?)?.toInt() ?? 0,
            title: (map['title'] ?? '').toString(),
          );
        }).toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _episodesByFolder[folder.id] = _demoEpisodes(folder);
      });
    } finally {
      _loadingFolders.remove(folder.id);
    }
  }

  List<_EpisodeData> _episodesOf(_FolderData folder) {
    return _episodesByFolder[folder.id] ?? _demoEpisodes(folder);
  }

  void _openEpisodeSheet(_EpisodeData episode) {
    DownloadLinksSheet.show(
      context,
      episodeId: episode.id,
      animeTitle: widget.animeTitle,
      episodeNumber: episode.number,
    );
  }

  Future<String?> _firstLinkFor(_EpisodeData episode) async {
    try {
      final dio = await _dio();
      final response = await dio.get(
        '${ApiConfig.episodes}/${episode.id}/download-links',
      );
      final List links = response.data['data']['links'] as List? ?? [];
      if (links.isEmpty) return null;
      return (links.first as Map)['url']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Queue every episode of a folder back-to-back using each episode's
  /// first mirror. Premium users skip the shortener gate server-side;
  /// free users must hold a valid shortener session.
  Future<void> _downloadAll(_FolderData folder) async {
    if (_isBulkRunning) return;
    await _loadEpisodes(folder);
    final episodes = _episodesOf(folder);
    if (episodes.isEmpty) return;

    setState(() {
      _bulkFolderId = folder.id;
      _bulkDone = 0;
      _bulkTotal = episodes.length;
    });

    final service = ref.read(downloadServiceProvider);
    var queued = 0;
    for (final episode in episodes) {
      if (!mounted) break;
      final url = await _firstLinkFor(episode);
      if (url != null) {
        final taskId = await service.enqueueEpisodeDownload(
          episodeId: episode.id,
          animeTitle: widget.animeTitle,
          episodeNumber: episode.number,
          quality: folder.quality,
          url: url,
          host: 'mirror',
        );
        if (taskId != null) queued++;
      }
      if (mounted) setState(() => _bulkDone++);
    }

    if (!mounted) return;
    setState(() => _bulkFolderId = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          queued > 0
              ? 'Queued $queued downloads from ${folder.name}'
              : 'No downloadable links in ${folder.name}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header + view toggle
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Episodes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              _ModeChip(
                label: 'Folders',
                icon: Icons.folder_outlined,
                selected: _foldersMode,
                onTap: () => setState(() => _foldersMode = true),
              ),
              const SizedBox(width: 8),
              _ModeChip(
                label: 'All',
                icon: Icons.format_list_numbered_rounded,
                selected: !_foldersMode,
                onTap: () => setState(() => _foldersMode = false),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              ),
            )
          else if (_foldersMode)
            ..._folders.map(_buildFolderCard)
          else
            _buildFlatEpisodeList(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Folders view
  // ---------------------------------------------------------------------------

  Widget _buildFolderCard(_FolderData folder) {
    final expanded = _expandedFolderId == folder.id;
    final episodes = _episodesOf(folder);
    final isLoadingEps = _loadingFolders.contains(folder.id);
    final isBulkHere = _bulkFolderId == folder.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: expanded
              ? AppTheme.primaryColor.withOpacity(0.35)
              : AppTheme.hairlineColor,
        ),
      ),
      child: Column(
        children: [
          // Folder header
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                _expandedFolderId = expanded ? null : folder.id;
              });
              if (!expanded) _loadEpisodes(folder);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.folder_rounded,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder.name,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${folder.episodeCount} EP • ${folder.quality}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Download-all for this folder
                  if (isBulkHere)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: _bulkTotal > 0 ? _bulkDone / _bulkTotal : null,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      tooltip: 'Download all in folder',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.download_for_offline_outlined,
                        color: AppTheme.primaryColor,
                        size: 22,
                      ),
                      onPressed: () => _downloadAll(folder),
                    ),

                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: AppTheme.motionFast,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bulk progress bar
          if (isBulkHere)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: _bulkTotal > 0 ? _bulkDone / _bulkTotal : null,
                  minHeight: 4,
                  backgroundColor: AppTheme.textHint.withOpacity(0.15),
                  color: AppTheme.primaryColor,
                ),
              ),
            ),

          // Episodes inside the folder
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: isLoadingEps
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      const Divider(height: 1, color: AppTheme.hairlineColor),
                      ...episodes.map((e) => _buildEpisodeRow(e)),
                    ],
                  ),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: AppTheme.motionMedium,
            sizeCurve: AppTheme.motionCurve,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Single-episode rows (shared by folders + flat view)
  // ---------------------------------------------------------------------------

  Widget _buildEpisodeRow(_EpisodeData episode) {
    return InkWell(
      onTap: () => _openEpisodeSheet(episode),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            // Episode number badge
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '${episode.number}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                episode.title.isNotEmpty
                    ? episode.title
                    : 'Episode ${episode.number}',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Single-episode download
            IconButton(
              tooltip: 'Download episode',
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.download_rounded,
                color: AppTheme.textSecondary,
                size: 20,
              ),
              onPressed: () => _openEpisodeSheet(episode),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Flat "all episodes" view
  // ---------------------------------------------------------------------------

  Widget _buildFlatEpisodeList() {
    final source = _folders.isNotEmpty ? _folders.first : null;
    if (source == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No episodes yet',
            style: TextStyle(color: AppTheme.textHint),
          ),
        ),
      );
    }
    final episodes = _episodesOf(source);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.hairlineColor),
      ),
      child: Column(
        children: episodes.map((e) => _buildEpisodeRow(e)).toList(),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.motionFast,
        curve: AppTheme.motionCurve,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withOpacity(0.15)
              : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor.withOpacity(0.5)
                : AppTheme.hairlineColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? AppTheme.primaryColor : AppTheme.textHint,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    selected ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
