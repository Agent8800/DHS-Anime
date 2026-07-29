import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../config/api_config.dart';
import '../../../core/constants/app_constants.dart';

/// Handles two notification channels:
///
///  1. **In-app feed** (the bell icon) — always works for every user.
///     New episodes and new donghua are broadcast by the backend and show
///     up here even when the system notification permission is denied.
///  2. **System push (FCM)** — only for users who granted the
///     notification permission. Their device token is registered with
///     the backend (`PUT /auth/fcm-token`); without the permission no
///     token is sent, so they only get the in-app bell-icon updates.
class AppNotificationService {
  final _secureStorage = const FlutterSecureStorage();
  FirebaseMessaging? _messaging;

  Dio _dio(String? token) {
    return Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      ),
    );
  }

  Future<String?> _token() =>
      _secureStorage.read(key: AppConstants.tokenKey);

  // ---------------------------------------------------------------------------
  // Push permission + FCM registration
  // ---------------------------------------------------------------------------

  /// Whether the user allowed system notifications on this device.
  Future<bool> isSystemPermissionGranted() async {
    return (await Permission.notification.status).isGranted;
  }

  /// Ask for the notification permission (Android 13+ / iOS) and, when
  /// granted, register the FCM token with the backend. When denied,
  /// nothing is registered — updates keep flowing to the bell icon only.
  Future<bool> requestPermissionAndRegister() async {
    // Runtime permission (Android 13+)
    final status = await Permission.notification.request();
    if (!status.isGranted) {
      return false;
    }

    try {
      // Firebase may be unconfigured in development — degrade gracefully
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _messaging = FirebaseMessaging.instance;

      // iOS style permission prompt + Android channel setup
      await _messaging!.requestPermission(alert: true, badge: true, sound: true);

      final fcmToken = await _messaging!.getToken();
      if (fcmToken != null) {
        await _registerTokenWithBackend(fcmToken);
      }

      // Keep the backend up to date when the token rotates
      _messaging!.onTokenRefresh.listen(_registerTokenWithBackend);
      return true;
    } catch (_) {
      // Push unavailable — in-app notifications keep working
      return false;
    }
  }

  Future<void> _registerTokenWithBackend(String fcmToken) async {
    try {
      final token = await _token();
      if (token == null) return; // only for signed-in users
      await _dio(token).put('${ApiConfig.auth}/fcm-token', data: {'fcmToken': fcmToken});
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // In-app feed (bell icon)
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchNotifications({
    int page = 1,
    int limit = 30,
  }) async {
    final token = await _token();
    try {
      final response = await _dio(token).get(
        '/notifications',
        queryParameters: {'page': page, 'limit': limit},
      );
      final List list = response.data['data']['notifications'] as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> fetchUnreadCount() async {
    final token = await _token();
    try {
      final response = await _dio(token).get('/notifications/unread-count');
      return (response.data['data']['unread'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markAsRead(String id) async {
    final token = await _token();
    if (token == null) return;
    try {
      await _dio(token).put('/notifications/$id/read');
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final token = await _token();
    if (token == null) return;
    try {
      await _dio(token).put('/notifications/read-all');
    } catch (_) {}
  }
}

final appNotificationServiceProvider =
    Provider<AppNotificationService>((ref) => AppNotificationService());
