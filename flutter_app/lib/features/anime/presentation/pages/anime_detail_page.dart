import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../download/presentation/widgets/download_links_sheet.dart';
import '../widgets/anime_info_section.dart';
import '../widgets/character_list_widget.dart';

class AnimeDetailPage extends ConsumerStatefulWidget {
  final String animeId;

  const AnimeDetailPage({super.key, required this.animeId});

  @override
  ConsumerState<AnimeDetailPage> createState() => _AnimeDetailPageState();
}

class _AnimeDetailPageState extends ConsumerState<AnimeDetailPage> {
  bool _isBookmarked = false;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: BouncingScrollPhysics(),
        slivers: [
          // Collapsible App Bar with Banner
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: Color(0xFF121212),
            leading: Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
            actions: [
              Container(
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: _isBookmarked ? AppTheme.primaryColor : Colors.white,
                  ),
                  onPressed: () {
                    setState(() => _isBookmarked = !_isBookmarked);
                  },
                ),
              ),
              Container(
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    Share.share('Check out this anime on DonghuaHub!');
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: 'https://via.placeholder.com/800x400/6C63FF/FFFFFF?text=Banner',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: AppTheme.cardColor,
                      highlightColor: AppTheme.surfaceColor,
                      child: Container(color: AppTheme.cardColor),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.cardColor,
                      child: Icon(Icons.movie, size: 60, color: AppTheme.textHint),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Poster
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: 'https://via.placeholder.com/120x170/6C63FF/FFFFFF?text=Poster',
                            width: 100,
                            height: 140,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: AppTheme.cardColor,
                              highlightColor: AppTheme.surfaceColor,
                              child: Container(width: 100, height: 140, color: AppTheme.cardColor),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 100,
                              height: 140,
                              color: AppTheme.cardColor,
                              child: Icon(Icons.movie, color: AppTheme.textHint),
                            ),
                          ),
                        ),

                        SizedBox(width: 16),

                        // Title & Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Battle Through The Heavens',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Dou Po Cangqiong',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildInfoChip(Icons.star, '8.5'),
                                  SizedBox(width: 8),
                                  _buildInfoChip(Icons.movie_outlined, '156 Episodes'),
                                  SizedBox(width: 8),
                                  _buildInfoChip(Icons.circle, 'Ongoing', color: Colors.green),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/anime/${widget.animeId}/episodes'),
                      icon: Icon(Icons.format_list_numbered_rounded),
                      label: Text('Episodes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Latest-first download shortcut
                        DownloadLinksSheet.show(
                          context,
                          episodeId: 'ep_1',
                          animeTitle: widget.animeId,
                          episodeNumber: 1,
                        );
                      },
                      icon: Icon(Icons.download_rounded),
                      label: Text('Download'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: Duration(milliseconds: 400)).slideY(begin: 0.2, end: 0),
          ),

          // Anime Info
          SliverToBoxAdapter(
            child: AnimeInfoSection(
              description: 'Xiao Yan, who was once a genius with extraordinary talent, suddenly lost everything three years ago. His powers disappeared, his reputation was ruined, and his engagement was broken off...',
              genres: ['Action', 'Fantasy', 'Martial Arts', 'Xianxia', 'Adventure'],
              studios: ['Shanghai Foch Film Culture Investment'],
              status: 'Ongoing',
              releaseDate: 'July 2024',
              type: 'TV',
            ).animate().fadeIn(duration: Duration(milliseconds: 400)),
          ),

          // Characters
          SliverToBoxAdapter(
            child: CharacterListWidget().animate().fadeIn(duration: Duration(milliseconds: 400)),
          ),

          // Episode List Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Episodes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/anime/${widget.animeId}/episodes'),
                    child: Text('View All'),
                  ),
                ],
              ),
            ),
          ),

          // Episode List (Limited)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildEpisodeTile(index + 1);
              },
              childCount: 5,
            ),
          ),

          // Related Series
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'Related Series',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Container(
                    width: 130,
                    margin: EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: 'https://via.placeholder.com/130x180',
                            width: 130,
                            height: 170,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: AppTheme.cardColor,
                              highlightColor: AppTheme.surfaceColor,
                              child: Container(color: AppTheme.cardColor),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppTheme.cardColor,
                              child: Icon(Icons.movie),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ).animate().fadeIn(duration: Duration(milliseconds: 400)),
          ),

          // Bottom padding
          SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {Color? color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.amber),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeTile(int episodeNumber) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: 'https://via.placeholder.com/100x60',
            width: 90,
            height: 60,
            fit: BoxFit.cover,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: AppTheme.cardColor,
              highlightColor: AppTheme.surfaceColor,
              child: Container(color: AppTheme.cardColor),
            ),
            errorWidget: (context, url, error) => Container(
              width: 90,
              height: 60,
              color: AppTheme.surfaceColor,
              child: Icon(Icons.play_circle_outline, color: AppTheme.textHint),
            ),
          ),
        ),
        title: Text(
          'Episode $episodeNumber',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Hindi • 1080p • 24 min',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        trailing: Icon(
          Icons.download_for_offline_outlined,
          color: AppTheme.primaryColor,
        ),
        onTap: () {
          // Streaming removed — show third-party download links instead
          DownloadLinksSheet.show(
            context,
            episodeId: 'ep_$episodeNumber',
            animeTitle: widget.animeId,
            episodeNumber: episodeNumber,
          );
        },
      ),
    );
  }
}
