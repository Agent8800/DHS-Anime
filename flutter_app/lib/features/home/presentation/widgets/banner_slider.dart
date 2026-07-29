import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class BannerSlider extends StatefulWidget {
  const BannerSlider({super.key});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Dummy banner data
  final List<Map<String, dynamic>> _banners = [
    {
      'id': 'anime_1',
      'title': 'Battle Through The Heavens',
      'description': 'New Season Now Streaming',
      'image': 'https://via.placeholder.com/800x400/6C63FF/FFFFFF?text=BTTH',
      'genres': ['Action', 'Fantasy', 'Martial Arts'],
      'rating': '8.5',
    },
    {
      'id': 'anime_2',
      'title': 'Soul Land',
      'description': 'Latest Episodes Available',
      'image': 'https://via.placeholder.com/800x400/FF6584/FFFFFF?text=Soul+Land',
      'genres': ['Action', 'Fantasy', 'Romance'],
      'rating': '8.8',
    },
    {
      'id': 'anime_3',
      'title': 'Stellar Transformations',
      'description': 'New Episodes Every Week',
      'image': 'https://via.placeholder.com/800x400/03DAC6/FFFFFF?text=Stellar',
      'genres': ['Action', 'Xianxia', 'Adventure'],
      'rating': '8.2',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(Duration(seconds: 5), () {
      if (mounted && _pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _banners.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return GestureDetector(
                onTap: () => context.push('/anime/${banner['id']}'),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background Image
                        CachedNetworkImage(
                          imageUrl: banner['image'],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: AppTheme.cardColor,
                            highlightColor: AppTheme.surfaceColor,
                            child: Container(color: AppTheme.cardColor),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.cardColor,
                            child: Icon(Icons.error),
                          ),
                        ),

                        // Gradient Overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.8),
                              ],
                            ),
                          ),
                        ),

                        // Content
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Genres
                              Row(
                                children: (banner['genres'] as List<String>).take(3).map((genre) {
                                  return Container(
                                    margin: EdgeInsets.only(right: 8),
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      genre,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                              SizedBox(height: 8),

                              // Title
                              Text(
                                banner['title'],
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              SizedBox(height: 4),

                              // Description & Rating
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      banner['description'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.star, color: Colors.amber, size: 18),
                                  SizedBox(width: 4),
                                  Text(
                                    banner['rating'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        SizedBox(height: 12),

        // Page Indicator
        SmoothPageIndicator(
          controller: _pageController,
          count: _banners.length,
          effect: ExpandingDotsEffect(
            dotColor: AppTheme.textHint.withOpacity(0.3),
            activeDotColor: AppTheme.primaryColor,
            dotHeight: 6,
            dotWidth: 6,
            expansionFactor: 4,
            spacing: 5,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: Duration(milliseconds: 600))
        .slideY(begin: 0.1, end: 0, duration: Duration(milliseconds: 600));
  }
}
