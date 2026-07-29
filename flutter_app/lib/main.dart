import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'config/router.dart';
import 'core/constants/app_constants.dart';
import 'core/services/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'features/notification/data/notification_service.dart';
import 'features/notification/presentation/providers/notification_provider.dart';
import 'shared/presentation/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for offline cache
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.settingsBox);
  await Hive.openBox(AppConstants.cacheBox);
  await Hive.openBox(AppConstants.downloadsBox);
  await Hive.openBox(AppConstants.historyBox);

  // Background episode downloads
  await FlutterDownloader.initialize(debug: false, ignoreSsl: true);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ProviderScope(
      // Clerk provides Google-only authentication to the whole app
      // (email/password is disabled — see features/auth).
      child: ClerkAuth(
        config: const ClerkAuthConfig(
          publishableKey: AppConstants.clerkPublishableKey,
        ),
        child: const DonghuaHubApp(),
      ),
    ),
  );
}

class DonghuaHubApp extends ConsumerStatefulWidget {
  const DonghuaHubApp({super.key});

  @override
  ConsumerState<DonghuaHubApp> createState() => _DonghuaHubAppState();
}

class _DonghuaHubAppState extends ConsumerState<DonghuaHubApp> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Restore a previous session, then register for push notifications
    // (only when the user grants the permission) and warm the bell badge.
    await ref.read(authServiceProvider.notifier).restoreSession();

    final notifications = ref.read(appNotificationServiceProvider);
    await notifications.requestPermissionAndRegister();
    if (mounted) {
      ref.read(notificationCenterProvider.notifier).refreshBadgeOnly();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(
        primaryColor: themeState.primaryColor,
        isAmoled: themeState.isAmoled,
      ),
      darkTheme: AppTheme.darkTheme(
        primaryColor: themeState.primaryColor,
        isAmoled: themeState.isAmoled,
      ),
      themeMode: ThemeMode.dark,
      routerConfig: router,
      // Uniform scroll motion across every screen
      scrollBehavior: const AppScrollBehavior(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child!,
        );
      },
    );
  }
}
