import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notification_service.dart';

class NotificationCenterState {
  final List<Map<String, dynamic>> notifications;
  final int unreadCount;
  final bool isLoading;
  final bool systemPermissionGranted;

  const NotificationCenterState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.systemPermissionGranted = true,
  });

  NotificationCenterState copyWith({
    List<Map<String, dynamic>>? notifications,
    int? unreadCount,
    bool? isLoading,
    bool? systemPermissionGranted,
  }) {
    return NotificationCenterState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      systemPermissionGranted:
          systemPermissionGranted ?? this.systemPermissionGranted,
    );
  }
}

/// Drives the bell icon badge and the notifications page.
class NotificationCenter extends StateNotifier<NotificationCenterState> {
  NotificationCenter(this._service) : super(const NotificationCenterState());

  final AppNotificationService _service;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    final results = await Future.wait([
      _service.fetchNotifications(),
      _service.fetchUnreadCount(),
      _service.isSystemPermissionGranted(),
    ]);
    state = state.copyWith(
      notifications: results[0] as List<Map<String, dynamic>>,
      unreadCount: results[1] as int,
      systemPermissionGranted: results[2] as bool,
      isLoading: false,
    );
  }

  Future<void> refreshBadgeOnly() async {
    final unread = await _service.fetchUnreadCount();
    state = state.copyWith(unreadCount: unread);
  }

  Future<void> markAsRead(String id) async {
    await _service.markAsRead(id);
    final updated = state.notifications.map((n) {
      if (n['_id'] == id || n['id'] == id) {
        return {...n, 'isRead': true};
      }
      return n;
    }).toList();
    state = state.copyWith(
      notifications: updated,
      unreadCount: (state.unreadCount - 1).clamp(0, 1 << 31),
    );
  }

  Future<void> markAllAsRead() async {
    await _service.markAllAsRead();
    state = state.copyWith(
      unreadCount: 0,
      notifications:
          state.notifications.map((n) => {...n, 'isRead': true}).toList(),
    );
  }

  void setSystemPermission(bool granted) {
    state = state.copyWith(systemPermissionGranted: granted);
  }
}

final notificationCenterProvider =
    StateNotifierProvider<NotificationCenter, NotificationCenterState>((ref) {
  return NotificationCenter(ref.watch(appNotificationServiceProvider));
});
