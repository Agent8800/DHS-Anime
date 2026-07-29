import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/animated_pressable.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../widgets/banner_slider.dart';
import '../widgets/section_header.dart';
import '../widgets/glassmorphism_header.dart';

/// Home — hero banner + every released donghua in one clean grid.
/// Continue Watching lives in the Watching tab; browsing lives in Search.
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
    // Warm the bell badge (new-episode / new-donghua notifications)
    Future.microtask(
      () => ref.read(notificationCenterProvider.notifier).refreshBadgeOnly(),
    );
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
    final headerHeight = MediaQuery.of(context).padding.top + 68;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Space under the floating header
              SliverToBoxAdapter(child: SizedBox(height: headerHeight)),

              // Hero banner
              const SliverToBoxAdapter(child: BannerSlider()),

              // Section title
              SliverToBoxAdapter(
                child: const SectionHeader(
                  title: 'All Releases',
                  trailing: _ReleaseCount(),
                ),
              ),

              // All released donghua — one poster grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.48,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _releases.length,
                  itemBuilder: (context, index) =>
                      _ReleaseCard(anime: _releases[index]),
                ),
              ),

              // Bottom padding for floating nav
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),

          // Floating glass header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlassmorphismHeader(scrollOffset: _scrollOffset),
          ),
        ],
      ),
    );
  }
}

class _ReleaseCount extends StatelessWidget {
  const _ReleaseCount();

  @override
  Widget build(BuildContext context) {
    return Text(
      '${_releases.length} titles',
      style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  final Map<String, dynamic> anime;

  const _ReleaseCard({required this.anime});

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: () => context.push('/anime/${anime['id']}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: AppTheme.shadowMd,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: anime['image'] as String,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: AppTheme.cardColor,
                        highlightColor: AppTheme.surfaceColor,
                        child: Container(color: AppTheme.cardColor),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.cardColor,
                        child: const Center(
                          child: Icon(Icons.movie_rounded,
                              size: 34, color: AppTheme.textHint),
                        ),
                      ),
                    ),

                    // Status tag — Ongoing / Completed
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _StatusPill(status: anime['status'] as String),
                    ),

                    // Episode count chip
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Text(
                          'EP ${anime['episodes']}',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 7),

          // Title only — status + episode count live on the poster
          Text(
            anime['title'] as String,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Solid status tag — ember for Ongoing, green for Completed.
class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final isOngoing = status.toLowerCase() == 'ongoing';
    final color =
        isOngoing ? AppTheme.primaryColor : const Color(0xFF3ECF8E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Released donghua (placeholder data until the API feed is wired —
/// swap with GET /api/anime?sort=newest).
final List<Map<String, dynamic>> _releases = List.generate(
  15,
  (index) => {
    'id': 'anime_$index',
    'title': [
      'Battle Through the Heavens',
      'Soul Land 2',
      'Swallowed Star',
      'Perfect World',
      'The Great Ruler',
      'Martial Universe',
      'Throne of Seal',
      'Tales of Demons and Gods',
      'Stellar Transformation',
      'A Will Eternal',
      'Renegade Immortal',
      'Jade Dynasty',
      'Fighting Spirit',
      'Spirit Sword Sovereign',
      'Demonic Ancestor',
    ][index],
    'image': 'https://via.placeholder.com/200x280',
    'rating': (9.2 - index * 0.3).toStringAsFixed(1),
    'episodes': 12 + index * 3,
    'status': index % 3 == 0 ? 'Ongoing' : 'Completed',
  },
);
