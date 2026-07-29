import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../notification/presentation/providers/notification_provider.dart';

/// Floating glass header — a single quiet bar that hovers above the
/// feed and matches the floating tab bar visually.
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
      margin: EdgeInsets.fromLTRB(16, statusBarHeight + 8, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF101014)
                  .withOpacity(0.55 + scrollIntensity * 0.25),
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              border: Border.all(
                color: Colors.white.withOpacity(0.05 + scrollIntensity * 0.06),
              ),
              boxShadow: AppTheme.shadowLg,
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
                          fontSize: 10.5,
                          letterSpacing: 0.3,
                          color: AppTheme.textHint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'DonghuaHub',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bell (in-app notifications — works without permission)
                _HeaderIcon(
                  icon: Icons.notifications_none_rounded,
                  badgeCount: unread,
                  onTap: () => context.push('/notifications'),
                ),
                const SizedBox(width: 10),

                // Profile
                GestureDetector(
                  onTap: () => context.push('/settings/account'),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
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
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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
        .fadeIn(duration: AppTheme.motionMedium)
        .slideY(
          begin: -0.5,
          end: 0,
          duration: AppTheme.motionMedium,
          curve: AppTheme.motionCurve,
        );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }
}

class _HeaderIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  const _HeaderIcon({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  State<_HeaderIcon> createState() => _HeaderIconState();
}

class _HeaderIconState extends State<_HeaderIcon> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.85 : 1.0,
        duration: AppTheme.motionFast,
        curve: AppTheme.motionCurve,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(widget.icon, color: AppTheme.textPrimary, size: 23),
              if (widget.badgeCount > 0)
                Positioned(
                  right: -3,
                  top: -3,
                  child: AnimatedContainer(
                    duration: AppTheme.motionFast,
                    padding: const EdgeInsets.all(3.5),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.badgeCount > 99 ? '99+' : '${widget.badgeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
