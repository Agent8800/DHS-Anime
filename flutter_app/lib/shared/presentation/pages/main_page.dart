import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/notification/presentation/providers/notification_provider.dart';

/// Shell with a floating glass tab bar — thumb-reachable, background
/// blurs behind it, active tab gets an ember-lit pill with a soft glow.
class MainPage extends ConsumerStatefulWidget {
  final Widget child;

  const MainPage({super.key, required this.child});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  int _currentIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', path: '/'),
    _NavItem(icon: Icons.search_rounded, activeIcon: Icons.search_rounded, label: 'Search', path: '/search'),
    _NavItem(icon: Icons.play_circle_outline_rounded, activeIcon: Icons.play_circle_rounded, label: 'Watching', path: '/watching'),
    _NavItem(icon: Icons.notifications_none_rounded, activeIcon: Icons.notifications_rounded, label: 'Alerts', path: '/notifications'),
    _NavItem(icon: Icons.tune_rounded, activeIcon: Icons.tune_rounded, label: 'Settings', path: '/settings'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).uri.path;
    final index = _navItems.indexWhere((item) => item.path == location);
    if (index != -1 && index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  void _onTap(int index) {
    if (index != _currentIndex) {
      HapticFeedback.selectionClick();
      setState(() => _currentIndex = index);
      context.go(_navItems[index].path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(
      notificationCenterProvider.select((s) => s.unreadCount),
    );

    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: _FloatingTabBar(
        items: _navItems,
        currentIndex: _currentIndex,
        unreadAlerts: unread,
        onTap: _onTap,
      ),
    );
  }
}

class _FloatingTabBar extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final int unreadAlerts;
  final ValueChanged<int> onTap;

  const _FloatingTabBar({
    required this.items,
    required this.currentIndex,
    required this.unreadAlerts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding > 0 ? 12 : 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: const Color(0xFF101014).withOpacity(0.72),
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              border: Border.all(color: AppTheme.hairlineColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isActive = index == currentIndex;
                return Expanded(
                  child: _TabItem(
                    item: item,
                    isActive: isActive,
                    badgeCount:
                        item.path == '/notifications' ? unreadAlerts : 0,
                    onTap: () => onTap(index),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: AppTheme.motionMedium)
        .slideY(
          begin: 0.9,
          end: 0,
          duration: AppTheme.motionMedium,
          curve: AppTheme.motionCurve,
        );
  }
}

class _TabItem extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final int badgeCount;
  final VoidCallback onTap;

  const _TabItem({
    required this.item,
    required this.isActive,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isActive ? AppTheme.primaryColor : AppTheme.textHint;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: AppTheme.motionFast,
        curve: AppTheme.motionCurve,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active pill behind the icon
            AnimatedContainer(
              duration: AppTheme.motionFast,
              curve: AppTheme.motionCurve,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              decoration: BoxDecoration(
                color: widget.isActive
                    ? AppTheme.primaryColor.withOpacity(0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.25),
                          blurRadius: 14,
                        ),
                      ]
                    : null,
              ),
              child: AnimatedSwitcher(
                duration: AppTheme.motionFast,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: Stack(
                  key: ValueKey(widget.isActive),
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      widget.isActive
                          ? widget.item.activeIcon
                          : widget.item.icon,
                      color: color,
                      size: 23,
                    ),
                    if (widget.badgeCount > 0)
                      Positioned(
                        right: -7,
                        top: -5,
                        child: Container(
                          padding: const EdgeInsets.all(3.5),
                          constraints: const BoxConstraints(
                              minWidth: 16, minHeight: 16),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              widget.badgeCount > 99
                                  ? '99+'
                                  : '${widget.badgeCount}',
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
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: AppTheme.motionFast,
              curve: AppTheme.motionCurve,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight:
                    widget.isActive ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
              child: Text(widget.item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}
