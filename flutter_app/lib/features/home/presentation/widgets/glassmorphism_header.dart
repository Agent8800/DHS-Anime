import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../notification/presentation/providers/notification_provider.dart';

/// Floating glass header that hovers above the home feed (same visual
/// language as the floating bottom navigation). The bell icon leads to
/// the notification center and shows an unread badge — updates land here
/// even when system notification permission is denied.
class GlassmorphismHeader extends ConsumerWidget {
  final double scrollOffset;

  const GlassmorphismHeader({super.key, required this.scrollOffset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final scrollIntensity = (scrollOffset / 150).clamp(0.0, 1.0);
    final unread = ref.watch(
      notificationCenterProvider.select((s) => s.unreadCount),
    );
    final auth = ref.watch(authServiceProvider);

    return Container(
      margin: EdgeInsets.fromLTRB(16, statusBarHeight + 10, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45 + scrollIntensity * 0.25),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.08 + scrollIntensity * 0.07),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Brand
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'DonghuaHub',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Notification bell (badge = unread in-app notifications)
                _buildIconButton(
                  context: context,
                  icon: Icons.notifications_outlined,
                  badgeCount: unread,
                  onTap: () => context.push('/notifications'),
                ),

                const SizedBox(width: 4),

                // Search
                _buildIconButton(
                  context: context,
                  icon: Icons.search_rounded,
                  onTap: () => context.push('/search'),
                ),

                const SizedBox(width: 8),

                // Profile
                GestureDetector(
                  onTap: () => context.push('/settings/account'),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (auth.name.isNotEmpty ? auth.name : 'U')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 400))
        .slideY(begin: -0.4, end: 0, duration: const Duration(milliseconds: 400));
  }

  Widget _buildIconButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: AppTheme.textPrimary, size: 25),
          if (badgeCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                decoration: const BoxDecoration(
                  color: AppTheme.errorColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 👋';
    if (hour < 17) return 'Good Afternoon ☀️';
    if (hour < 21) return 'Good Evening 🌅';
    return 'Good Night 🌙';
  }
}
