import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/app_theme.dart';
import '../providers/notification_provider.dart';

/// The bell-icon feed. Every user sees new-episode and new-donghua
/// updates here — including users who denied the system notification
/// permission (they just don't get a push; the banner below lets them
/// change their mind).
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(notificationCenterProvider.notifier).refresh(),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'new_episode':
        return Icons.tv_rounded;
      case 'new_donghua':
        return Icons.auto_awesome_rounded;
      case 'announcement':
        return Icons.campaign_outlined;
      case 'offer':
        return Icons.local_offer_outlined;
      case 'maintenance':
        return Icons.build_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'new_episode':
        return AppTheme.primaryColor;
      case 'new_donghua':
        return const Color(0xFF4CAF50);
      case 'offer':
        return const Color(0xFFFF9800);
      default:
        return AppTheme.textSecondary;
    }
  }

  Future<void> _openNotification(Map<String, dynamic> notification) async {
    final id = notification['_id']?.toString() ?? notification['id']?.toString() ?? '';
    if (id.isNotEmpty && notification['isRead'] != true) {
      ref.read(notificationCenterProvider.notifier).markAsRead(id);
    }

    final data = notification['data'];
    final animeId = data is Map ? data['animeId']?.toString() : null;
    if (animeId != null && animeId.isNotEmpty && mounted) {
      context.push('/anime/$animeId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationCenterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (state.notifications.any((n) => n['isRead'] != true))
            TextButton(
              onPressed: () =>
                  ref.read(notificationCenterProvider.notifier).markAllAsRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () => ref.read(notificationCenterProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // Permission banner — the "only show in notification icon" mode
            if (!state.systemPermissionGranted) _buildPermissionBanner(),

            if (state.isLoading && state.notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                ),
              )
            else if (state.notifications.isEmpty)
              _buildEmptyState()
            else
              ...state.notifications.asMap().entries.map(
                    (entry) => _buildNotificationTile(
                      entry.value,
                      entry.key,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_off_outlined,
              color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'System alerts are off — you still get every update here.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              await openAppSettings();
              if (mounted) {
                ref.read(notificationCenterProvider.notifier).refresh();
              }
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 400));
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: AppTheme.textHint.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'New episodes will show up here.',
            style: TextStyle(color: AppTheme.textHint, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notification, int index) {
    final type = notification['type']?.toString() ?? 'system';
    final isRead = notification['isRead'] == true;
    final createdAt = DateTime.tryParse(
          notification['createdAt']?.toString() ?? '',
        ) ??
        DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isRead ? AppTheme.cardColor.withOpacity(0.6) : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: isRead
            ? null
            : Border.all(color: _typeColor(type).withOpacity(0.35)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _typeColor(type).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_typeIcon(type), color: _typeColor(type), size: 22),
        ),
        title: Text(
          notification['title']?.toString() ?? '',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
            fontSize: 14.5,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              notification['body']?.toString() ?? '',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              timeago.format(createdAt),
              style: const TextStyle(color: AppTheme.textHint, fontSize: 11.5),
            ),
          ],
        ),
        trailing: isRead
            ? null
            : Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () => _openNotification(notification),
      ),
    )
        .animate()
        .fadeIn(
          duration: const Duration(milliseconds: 350),
          delay: Duration(milliseconds: (index.clamp(0, 10)) * 60),
        )
        .slideY(begin: 0.1, end: 0);
  }
}
