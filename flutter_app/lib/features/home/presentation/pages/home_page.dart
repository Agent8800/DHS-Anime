import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/banner_slider.dart';
import '../widgets/section_header.dart';
import '../widgets/anime_card.dart';
import '../widgets/continue_watching_card.dart';
import '../widgets/glassmorphism_header.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
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
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: BouncingScrollPhysics(),
            slivers: [
              // Glassmorphism Header
              SliverToBoxAdapter(
                child: GlassmorphismHeader(scrollOffset: _scrollOffset),
              ),

              // Banner Slider
              SliverToBoxAdapter(
                child: BannerSlider(),
              ),

              // Continue Watching
              SliverToBoxAdapter(
                child: _buildContinueWatching(),
              ),

              // Recently Updated
              SliverToBoxAdapter(
                child: _buildAnimeSection(
                  'Recently Updated',
                  _getDummyAnimeList(),
                ),
              ),

              // Trending Now
              SliverToBoxAdapter(
                child: _buildAnimeSection(
                  'Trending Now 🔥',
                  _getDummyAnimeList(),
                ),
              ),

              // Popular
              SliverToBoxAdapter(
                child: _buildAnimeSection(
                  'Popular',
                  _getDummyAnimeList(),
                ),
              ),

              // Latest Episodes
              SliverToBoxAdapter(
                child: _buildLatestEpisodes(),
              ),

              // Genres
              SliverToBoxAdapter(
                child: _buildGenres(),
              ),

              // Top Rated
              SliverToBoxAdapter(
                child: _buildAnimeSection(
                  'Top Rated ⭐',
                  _getDummyAnimeList(),
                ),
              ),

              // Random Picks
              SliverToBoxAdapter(
                child: _buildAnimeSection(
                  'Random Picks 🎲',
                  _getDummyAnimeList(),
                ),
              ),

              // Bottom padding for floating nav
              SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContinueWatching() {
    // Dummy continue watching data
    final items = List.generate(5, (index) => index);

    if (items.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Continue Watching',
          onSeeAll: () {},
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return ContinueWatchingCard(
                title: 'Battle Through The Heavens',
                episode: 'Episode ${index + 5}',
                progress: (index + 1) * 0.15,
                imageUrl: 'https://via.placeholder.com/300x170',
                onTap: () => context.push('/player/ep_$index?animeId=anime_1&episode=${index + 5}'),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(duration: Duration(milliseconds: 500));
  }

  Widget _buildAnimeSection(String title, List<Map<String, dynamic>> animeList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          onSeeAll: () {},
        ),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: animeList.length,
            itemBuilder: (context, index) {
              final anime = animeList[index];
              return AnimeCard(
                title: anime['title'],
                imageUrl: anime['image'],
                rating: anime['rating'],
                onTap: () => context.push('/anime/${anime['id']}'),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(duration: Duration(milliseconds: 500));
  }

  Widget _buildLatestEpisodes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Latest Episodes',
          onSeeAll: () {},
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          itemBuilder: (context, index) {
            return Card(
              margin: EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: 'https://via.placeholder.com/120x80',
                    width: 100,
                    height: 70,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: AppTheme.cardColor,
                      highlightColor: AppTheme.surfaceColor,
                      child: Container(color: AppTheme.cardColor),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 100,
                      height: 70,
                      color: AppTheme.cardColor,
                      child: Icon(Icons.error),
                    ),
                  ),
                ),
                title: Text(
                  'Douluo Continent - Ep ${index + 1}',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Hindi • 1080p',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                trailing: Icon(
                  Icons.play_circle_outline,
                  color: AppTheme.primaryColor,
                ),
                onTap: () {},
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(duration: Duration(milliseconds: 500));
  }

  Widget _buildGenres() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Browse by Genre',
          onSeeAll: () {},
        ),
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: 10,
            itemBuilder: (context, index) {
              final genres = ['Action', 'Fantasy', 'Martial Arts', 'Xianxia', 'Drama', 'Comedy', 'Romance', 'Sci-Fi', 'Adventure', 'Cultivation'];
              return Padding(
                padding: EdgeInsets.only(right: 10),
                child: Chip(
                  label: Text(genres[index]),
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                  labelStyle: TextStyle(color: AppTheme.primaryColor),
                  side: BorderSide.none,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 24),
      ],
    ).animate().fadeIn(duration: Duration(milliseconds: 500));
  }

  List<Map<String, dynamic>> _getDummyAnimeList() {
    return List.generate(10, (index) => {
      'id': 'anime_$index',
      'title': 'Anime Title ${index + 1}',
      'image': 'https://via.placeholder.com/200x280',
      'rating': (7 + index * 0.3).toStringAsFixed(1),
    });
  }
}
