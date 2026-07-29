import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(Duration(seconds: 2));

    if (!mounted) return;

    final settingsBox = Hive.box(AppConstants.settingsBox);
    final isFirstLaunch = settingsBox.get(AppConstants.firstLaunchKey, defaultValue: true);
    final token = settingsBox.get(AppConstants.tokenKey);

    if (isFirstLaunch) {
      context.go('/onboarding');
    } else if (token != null) {
      context.go('/');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF121212),
              Color(0xFF1E1E2E),
              Color(0xFF121212),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.play_circle_fill_rounded,
                size: 60,
                color: Colors.white,
              ),
            )
                .animate()
                .fadeIn(duration: Duration(milliseconds: 800))
                .scale(begin: Offset(0.5, 0.5), end: Offset(1, 1), duration: Duration(milliseconds: 800), curve: Curves.easeOutBack),

            SizedBox(height: 24),

            // App Name
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: 1.5,
              ),
            )
                .animate(delay: Duration(milliseconds: 300))
                .fadeIn(duration: Duration(milliseconds: 600))
                .slideY(begin: 0.3, end: 0, duration: Duration(milliseconds: 600)),

            SizedBox(height: 8),

            // Tagline
            Text(
              'Download & Watch Your Favorite Donghua',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            )
                .animate(delay: Duration(milliseconds: 500))
                .fadeIn(duration: Duration(milliseconds: 600)),

            SizedBox(height: 60),

            // Loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
                .animate(delay: Duration(milliseconds: 800))
                .fadeIn(duration: Duration(milliseconds: 400)),
          ],
        ),
      ),
    );
  }
}
