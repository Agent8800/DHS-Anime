import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class EpisodeListWidget extends StatelessWidget {
  final String animeId;
  final List<Map<String, dynamic>> episodes;

  const EpisodeListWidget({
    super.key,
    required this.animeId,
    required this.episodes,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final episode = episodes[index];
        return _buildEpisodeTile(context, episode);
      },
    );
  }

  Widget _buildEpisodeTile(BuildContext context, Map<String, dynamic> episode) {
    final progress = episode['progress'] as double? ?? 0.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          context.push('/player/${episode['id']}?animeId=$animeId&episode=${episode['number']}');
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: episode['thumbnail'] ?? 'https://via.placeholder.com/100x60',
                      width: 100,
                      height: 65,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: AppTheme.cardColor,
                        highlightColor: AppTheme.surfaceColor,
                        child: Container(width: 100, height: 65, color: AppTheme.cardColor),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 100,
                        height: 65,
                        color: AppTheme.surfaceColor,
                        child: Icon(Icons.play_circle_outline, color: AppTheme.textHint),
                      ),
                    ),

                    // Progress bar
                    if (progress > 0)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.black.withOpacity(0.5),
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          minHeight: 3,
                        ),
                      ),

                    // Play icon
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Episode ${episode['number']}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (episode['title'] != null && episode['title'].isNotEmpty) ...[
                      SizedBox(height: 2),
                      Text(
                        episode['title'],
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: 6),
                    Row(
                      children: [
                        _buildTag(episode['language'] ?? 'Hindi'),
                        SizedBox(width: 6),
                        _buildTag(episode['quality'] ?? '1080p'),
                        if (episode['duration'] != null) ...[
                          SizedBox(width: 6),
                          _buildTag('${episode['duration']} min'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // More options
              PopupMenuButton(
                icon: Icon(Icons.more_vert, color: AppTheme.textHint),
                color: AppTheme.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.download_outlined, size: 20, color: AppTheme.textPrimary),
                        SizedBox(width: 12),
                        Text('Download', style: TextStyle(color: AppTheme.textPrimary)),
                      ],
                    ),
                    onTap: () {},
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.share_outlined, size: 20, color: AppTheme.textPrimary),
                        SizedBox(width: 12),
                        Text('Share', style: TextStyle(color: AppTheme.textPrimary)),
                      ],
                    ),
                    onTap: () {},
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.report_outlined, size: 20, color: AppTheme.errorColor),
                        SizedBox(width: 12),
                        Text('Report', style: TextStyle(color: AppTheme.errorColor)),
                      ],
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
