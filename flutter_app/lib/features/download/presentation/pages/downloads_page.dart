import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class DownloadsPage extends ConsumerStatefulWidget {
  const DownloadsPage({super.key});

  @override
  ConsumerState<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends ConsumerState<DownloadsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Downloads'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: [
            Tab(text: 'Downloading'),
            Tab(text: 'Completed'),
            Tab(text: 'Failed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDownloadingList(),
          _buildCompletedList(),
          _buildFailedList(),
        ],
      ),
    );
  }

  Widget _buildDownloadingList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        final progress = (index + 1) * 0.25;
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: 'https://via.placeholder.com/80x50',
                        width: 80,
                        height: 55,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          width: 80,
                          height: 55,
                          color: AppTheme.surfaceColor,
                          child: Icon(Icons.movie, color: AppTheme.textHint),
                        ),
                      ),
                    ),
                    SizedBox(width: 14),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Anime Title ${index + 1}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Episode ${index + 1} • 1080p',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Progress indicator
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),

                // Progress bar
                LinearPercentIndicator(
                  padding: EdgeInsets.zero,
                  lineHeight: 6,
                  percent: progress,
                  backgroundColor: AppTheme.textHint.withOpacity(0.2),
                  progressColor: AppTheme.primaryColor,
                  barRadius: Radius.circular(3),
                  animation: true,
                  animationDuration: 500,
                ),
                SizedBox(height: 10),

                // Speed & remaining time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '2.5 MB/s',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '${(index + 1) * 3} min remaining',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.pause, size: 18),
                      label: Text('Pause'),
                    ),
                    SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.cancel_outlined, size: 18, color: AppTheme.errorColor),
                      label: Text('Cancel', style: TextStyle(color: AppTheme.errorColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(
          duration: Duration(milliseconds: 400),
          delay: Duration(milliseconds: index * 100),
        );
      },
    );
  }

  Widget _buildCompletedList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {},
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: 'https://via.placeholder.com/80x50',
                      width: 80,
                      height: 55,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 80,
                        height: 55,
                        color: AppTheme.surfaceColor,
                        child: Icon(Icons.movie, color: AppTheme.textHint),
                      ),
                    ),
                  ),
                  SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Anime Title ${index + 1}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Episode ${index + 1}',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '1080p',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '450 MB',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textHint,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Play button
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: AppTheme.primaryColor,
                      size: 22,
                    ),
                  ),

                  // Delete button
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: AppTheme.textHint, size: 20),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(
          duration: Duration(milliseconds: 400),
          delay: Duration(milliseconds: index * 100),
        );
      },
    );
  }

  Widget _buildFailedList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 2,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: 'https://via.placeholder.com/80x50',
                    width: 80,
                    height: 55,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 55,
                      color: AppTheme.surfaceColor,
                      child: Icon(Icons.movie, color: AppTheme.textHint),
                    ),
                  ),
                ),
                SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anime Title ${index + 1}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Download failed • Network error',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Retry button
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.refresh, size: 18),
                  label: Text('Retry'),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(
          duration: Duration(milliseconds: 400),
          delay: Duration(milliseconds: index * 100),
        );
      },
    );
  }
}
