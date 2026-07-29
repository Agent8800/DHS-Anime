import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../config/api_config.dart';
import '../constants/app_constants.dart';

/// Authentication is handled exclusively by **Clerk + Google OAuth**.
/// Email/password signup and login are intentionally not supported —
/// Google accounts are the only identity provider (enable "Google" and
/// disable "Email" in the Clerk dashboard).
///
/// After a successful Clerk sign-in the profile is synced with our
/// backend (`POST /auth/sync`) which returns the API JWT used by
/// [AuthInterceptor] for all subsequent requests.
class AuthState {
  final bool isSignedIn;
  final String clerkId;
  final String name;
  final String email;
  final String avatar;

  const AuthState({
    this.isSignedIn = false,
    this.clerkId = '',
    this.name = '',
    this.email = '',
    this.avatar = '',
  });

  AuthState copyWith({
    bool? isSignedIn,
    String? clerkId,
    String? name,
    String? email,
    String? avatar,
  }) {
    return AuthState(
      isSignedIn: isSignedIn ?? this.isSignedIn,
      clerkId: clerkId ?? this.clerkId,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
    );
  }
}

class AuthService extends StateNotifier<AuthState> {
  AuthService() : super(const AuthState());

  final _secureStorage = const FlutterSecureStorage();

  Box get _settingsBox => Hive.box(AppConstants.settingsBox);

  /// Whether a backend session exists locally (fast path for splash).
  bool get hasStoredSession =>
      _settingsBox.get(AppConstants.tokenKey) != null;

  /// Restore a previous session into state (called on app start).
  Future<void> restoreSession() async {
    final token = await _secureStorage.read(key: AppConstants.tokenKey) ??
        _settingsBox.get(AppConstants.tokenKey);
    if (token == null) return;

    state = AuthState(
      isSignedIn: true,
      clerkId: _settingsBox.get(AppConstants.userIdKey, defaultValue: ''),
      name: _settingsBox.get(AppConstants.userNameKey, defaultValue: ''),
      email: _settingsBox.get(AppConstants.userEmailKey, defaultValue: ''),
      avatar: _settingsBox.get(AppConstants.userAvatarKey, defaultValue: ''),
    );
  }

  /// Continue-with-Google through Clerk's hosted OAuth flow.
  Future<bool> signInWithGoogle(BuildContext context) async {
    final clerkAuth = ClerkAuth.of(context).auth;

    // Opens Clerk's Google OAuth flow (in-app browser / Custom Tab).
    // `ssoSignIn` is provided by the clerk_auth SDK (currently in beta —
    // if a future release renames it, this is the single place to adjust).
    // It resolves once the user completes (or cancels) the Google picker.
    final dynamic auth = clerkAuth;
    await auth.ssoSignIn(context, clerk.OAuthStrategy.google);

    if (clerkAuth.isSignedIn != true) {
      return false;
    }

    await _syncWithBackend(clerkAuth);
    return true;
  }

  /// Push the Clerk profile to our backend and store the returned JWT.
  Future<void> _syncWithBackend(dynamic clerkAuth) async {
    final dynamic user = clerkAuth.user;

    final clerkId = _read(() => user?.id)?.toString() ?? '';
    final email = _firstNonEmpty([
      _read(() => user?.email),
      _read(() => (user?.emailAddresses as List?)?.first?.emailAddress),
      _read(() => user?.primaryEmailAddress?.emailAddress),
    ]);
    final name = _firstNonEmpty([
      _read(() => user?.fullName),
      _read(() => user?.username),
      _read(() => [user?.firstName, user?.lastName]
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .join(' ')),
    ], fallback: 'User');
    final avatar = _firstNonEmpty([
      _read(() => user?.profileImageUrl),
      _read(() => user?.imageUrl),
    ]);

    if (clerkId.isEmpty || email.isEmpty) {
      throw Exception('Clerk did not return a usable profile');
    }

    final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
    final response = await dio.post(
      '${ApiConfig.auth}/sync',
      data: {
        'clerkId': clerkId,
        'email': email,
        'name': name,
        'avatar': avatar,
      },
    );

    final data = response.data['data'];
    final token = data['token'] as String;

    // Persist session (secure storage for the token, Hive for profile)
    await _secureStorage.write(key: AppConstants.tokenKey, value: token);
    await _settingsBox.put(AppConstants.tokenKey, token);
    await _settingsBox.put(AppConstants.userIdKey, clerkId);
    await _settingsBox.put(AppConstants.userNameKey, name);
    await _settingsBox.put(AppConstants.userEmailKey, email);
    await _settingsBox.put(AppConstants.userAvatarKey, avatar);

    state = AuthState(
      isSignedIn: true,
      clerkId: clerkId,
      name: name,
      email: email,
      avatar: avatar,
    );
  }

  /// Sign out of Clerk and wipe the local session.
  Future<void> signOut(BuildContext context) async {
    try {
      final dynamic auth = ClerkAuth.of(context).auth;
      await auth.signOut();
    } catch (_) {
      // Clerk not mounted / already signed out — continue cleanup anyway
    }

    await _secureStorage.delete(key: AppConstants.tokenKey);
    await _settingsBox.delete(AppConstants.tokenKey);
    await _settingsBox.delete(AppConstants.userIdKey);
    await _settingsBox.delete(AppConstants.userNameKey);
    await _settingsBox.delete(AppConstants.userEmailKey);
    await _settingsBox.delete(AppConstants.userAvatarKey);

    state = const AuthState();
  }

  /// Dynamic-safe field reader: the clerk_auth beta model shape varies
  /// between releases, so unknown getters must never crash the flow.
  static dynamic _read(dynamic Function() fn) {
    try {
      return fn();
    } catch (_) {
      return null;
    }
  }

  static String _firstNonEmpty(List<dynamic> values, {String fallback = ''}) {
    for (final v in values) {
      final s = v?.toString() ?? '';
      if (s.isNotEmpty) return s;
    }
    return fallback;
  }
}

final authServiceProvider =
    StateNotifierProvider<AuthService, AuthState>((ref) => AuthService());
