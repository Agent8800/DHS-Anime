import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/api_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/download_service.dart';

/// Shows the third-party download links for an episode (Mega, GDrive,
/// Terabox, Telegram…). In-app streaming is not offered — users download
/// to the "DHS Anime" folder (or their chosen location) and play offline
/// with the built-in player.
class DownloadLinksSheet extends ConsumerStatefulWidget {
  final String episodeId;
  final String animeTitle;
  final int episodeNumber;

  const DownloadLinksSheet({
    super.key,
    required this.episodeId,
    required this.animeTitle,
    required this.episodeNumber,
  });

  /// Convenience helper used by all episode entry points.
  static Future<void> show(
    BuildContext context, {
    required String episodeId,
    required String animeTitle,
    required int episodeNumber,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DownloadLinksSheet(
        episodeId: episodeId,
        animeTitle: animeTitle,
        episodeNumber: episodeNumber,
      ),
    );
  }

  @override
  ConsumerState<DownloadLinksSheet> createState() => _DownloadLinksSheetState();
}

class _DownloadLinksSheetState extends ConsumerState<DownloadLinksSheet> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _links = [];
  bool _showingDemoLinks = false;

  @override
  void initState() {
    super.initState();
    _fetchLinks();
  }

  Future<void> _fetchLinks() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: AppConstants.tokenKey);
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      final response =
          await dio.get('${ApiConfig.episodes}/${widget.episodeId}/download-links');
      final List links = response.data['data']['links'] as List;

      setState(() {
        _links = links.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } on DioException catch (e) {
      // Backend unreachable (dev/demo) — show sample hosts so the flow
      // stays testable, clearly flagged as demo links.
      setState(() {
        _loading = false;
        _showingDemoLinks = true;
        _error = e.response?.statusCode == 404 ? 'No links yet' : null;
        _links = e.response?.statusCode == 404
            ? []
            : [
                {
                  'host': 'mega',
                  'label': 'Mega Mirror',
                  'url': 'https://mega.nz/file/example',
                  'quality': '1080p',
                  'fileSize': 482344960,
                },
                {
                  'host': 'gdrive',
                  'label': 'GDrive Mirror',
                  'url': 'https://drive.google.com/file/d/example',
                  'quality': '720p',
                  'fileSize': 325058560,
                },
                {
                  'host': 'telegram',
                  'label': 'Telegram Channel',
                  'url': 'https://t.me/example',
                  'quality': '480p',
                  'fileSize': 188743680,
                },
              ];
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Could not load download links';
      });
    }
  }

  Future<void> _startDownload(Map<String, dynamic> link) async {
    final service = ref.read(downloadServiceProvider);
    final taskId = await service.enqueueEpisodeDownload(
      episodeId: widget.episodeId,
      animeTitle: widget.animeTitle,
      episodeNumber: widget.episodeNumber,
      quality: link['quality']?.toString() ?? '720p',
      url: link['url']?.toString() ?? '',
      host: link['host']?.toString() ?? 'direct',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          taskId != null
              ? 'Download started — saving to ${service.configuredPath}'
              : 'Could not start download',
        ),
        action: taskId != null
            ? SnackBarAction(
                label: 'View',
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
    );
    if (taskId != null) Navigator.pop(context);
  }

  Future<void> _openInBrowser(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        await Clipboard.setData(ClipboardData(text: url));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link copied to clipboard')),
        );
      }
    }
  }

  IconData _hostIcon(String host) {
    final h = host.toLowerCase();
    if (h.contains('mega')) return Icons.cloud_circle_outlined;
    if (h.contains('gdrive') || h.contains('drive')) return Icons.add_to_drive_rounded;
    if (h.contains('tera')) return Icons.cloud_upload_outlined;
    if (h.contains('telegram')) return Icons.send_rounded;
    if (h.contains('torrent')) return Icons.hub_outlined;
    return Icons.link_rounded;
  }

  String _formatSize(dynamic bytes) {
    final b = (bytes as num?)?.toInt() ?? 0;
    if (b <= 0) return '';
    if (b >= 1 << 30) return '${(b / (1 << 30)).toStringAsFixed(2)} GB';
    if (b >= 1 << 20) return '${(b / (1 << 20)).toStringAsFixed(0)} MB';
    return '${(b / (1 << 10)).toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final downloadService = ref.watch(downloadServiceProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.download_for_offline_outlined,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Download Episode ${widget.episodeNumber}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.animeTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Destination hint
            Row(
              children: [
                const Icon(Icons.folder_open_rounded,
                    size: 15, color: AppTheme.textHint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Saving to: ${downloadService.configuredPath}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_showingDemoLinks)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Preview mirrors (backend not connected)',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),

            // Content
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                ),
              )
            else if (_links.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    _error ??
                        'No download links yet — check back after the next update.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _links.length,
                  itemBuilder: (context, index) => _buildLinkTile(_links[index]),
                ),
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkTile(Map<String, dynamic> link) {
    final host = link['host']?.toString() ?? 'link';
    final label = (link['label']?.toString().isNotEmpty == true)
        ? link['label'].toString()
        : host;
    final quality = link['quality']?.toString() ?? '';
    final size = _formatSize(link['fileSize']);
    final url = link['url']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_hostIcon(host), color: AppTheme.primaryColor, size: 22),
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          [if (quality.isNotEmpty) quality, if (size.isNotEmpty) size].join(' • '),
          style: const TextStyle(color: AppTheme.textHint, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Open in browser',
              icon: const Icon(Icons.open_in_new_rounded,
                  color: AppTheme.textSecondary, size: 20),
              onPressed: () => _openInBrowser(url),
            ),
            IconButton(
              tooltip: 'Download',
              icon: const Icon(Icons.download_rounded,
                  color: AppTheme.primaryColor, size: 24),
              onPressed: () => _startDownload(link),
            ),
          ],
        ),
        onTap: () => _startDownload(link),
      ),
    );
  }
}
