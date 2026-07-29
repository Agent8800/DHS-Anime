import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/anime/presentation/pages/anime_detail_page.dart';
import '../features/episode/presentation/pages/episode_page.dart';
import '../features/player/presentation/pages/player_page.dart';
import '../features/search/presentation/pages/search_page.dart';
import '../features/bookmark/presentation/pages/bookmarks_page.dart';
import '../features/download/presentation/pages/downloads_page.dart';
import '../features/notification/presentation/pages/notifications_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/settings/presentation/pages/theme_settings_page.dart';
import '../features/settings/presentation/pages/account_page.dart';
import '../features/settings/presentation/pages/about_page.dart';
import '../features/settings/presentation/pages/privacy_policy_page.dart';
import '../shared/presentation/pages/main_page.dart';
import '../shared/presentation/pages/splash_page.dart';
import '../shared/presentation/pages/onboarding_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      // Login
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),

      // Main Shell (Bottom Navigation)
      ShellRoute(
        builder: (context, state, child) => MainPage(child: child),
        routes: [
          // Home
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: const HomePage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                );
                return FadeTransition(
                  opacity: curved,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.02), end: Offset.zero)
                        .animate(curved),
                    child: child,
                  ),
                );
              },
            ),
          ),

          // Search
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: const SearchPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                );
                return FadeTransition(
                  opacity: curved,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.02), end: Offset.zero)
                        .animate(curved),
                    child: child,
                  ),
                );
              },
            ),
          ),

          // Bookmarks (Watching)
          GoRoute(
            path: '/watching',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: const BookmarksPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                );
                return FadeTransition(
                  opacity: curved,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.02), end: Offset.zero)
                        .animate(curved),
                    child: child,
                  ),
                );
              },
            ),
          ),

          // Settings
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: const SettingsPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                );
                return FadeTransition(
                  opacity: curved,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.02), end: Offset.zero)
                        .animate(curved),
                    child: child,
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Anime Detail
      GoRoute(
        path: '/anime/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AnimeDetailPage(animeId: id);
        },
      ),

      // Episode List
      GoRoute(
        path: '/anime/:animeId/episodes',
        builder: (context, state) {
          final animeId = state.pathParameters['animeId']!;
          return EpisodePage(animeId: animeId);
        },
      ),

      // Offline Player (plays downloaded files only — streaming removed)
      GoRoute(
        path: '/player/:episodeId',
        builder: (context, state) {
          final episodeId = state.pathParameters['episodeId']!;
          final animeId = state.uri.queryParameters['animeId'] ?? '';
          final episodeNumber = int.tryParse(state.uri.queryParameters['episode'] ?? '1') ?? 1;
          return PlayerPage(
            episodeId: episodeId,
            animeId: animeId,
            episodeNumber: episodeNumber,
            filePath: state.uri.queryParameters['file'],
            title: state.uri.queryParameters['title'],
          );
        },
      ),

      // Downloads
      GoRoute(
        path: '/downloads',
        builder: (context, state) => const DownloadsPage(),
      ),

      // Notification Center (bell icon in the floating header)
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),

      // Theme Settings
      GoRoute(
        path: '/settings/theme',
        builder: (context, state) => const ThemeSettingsPage(),
      ),

      // Account
      GoRoute(
        path: '/settings/account',
        builder: (context, state) => const AccountPage(),
      ),

      // About
      GoRoute(
        path: '/settings/about',
        builder: (context, state) => const AboutPage(),
      ),

      // Privacy Policy
      GoRoute(
        path: '/settings/privacy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Page not found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(state.error?.toString() ?? 'Unknown error'),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
