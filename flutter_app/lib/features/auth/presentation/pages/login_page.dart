import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';

/// Only one way in: **Continue with Google** via Clerk.
/// New users are signed up automatically by Clerk on their first Google
/// login — there is no separate email/password signup by design.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isLoading = false;

  Future<void> _continueWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final success =
          await ref.read(authServiceProvider.notifier).signInWithGoogle(context);

      if (!mounted) return;

      if (success) {
        context.go('/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in was cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google login failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E1E2E),
              Color(0xFF121212),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),

                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_circle_fill_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                )
                    .animate()
                    .fadeIn(duration: const Duration(milliseconds: 600))
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutBack,
                    ),

                const SizedBox(height: 28),

                Text(
                  'Welcome to DonghuaHub',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate(delay: const Duration(milliseconds: 200))
                    .fadeIn(duration: const Duration(milliseconds: 500)),

                const SizedBox(height: 10),

                Text(
                  'Download and watch your favorite donghua offline.',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate(delay: const Duration(milliseconds: 300))
                    .fadeIn(duration: const Duration(milliseconds: 500)),

                const Spacer(),

                // Continue with Google (the ONLY auth method)
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _continueWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black54),
                            ),
                          )
                        : Image.network(
                            'https://www.google.com/favicon.ico',
                            width: 22,
                            height: 22,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.g_mobiledata, size: 26),
                          ),
                    label: Text(
                      _isLoading ? 'Signing in…' : 'Continue with Google',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                    .animate(delay: const Duration(milliseconds: 400))
                    .fadeIn(duration: const Duration(milliseconds: 500))
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 18),

                Text(
                  'New here? Your account is created automatically\nwhen you continue with Google.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textHint,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate(delay: const Duration(milliseconds: 500))
                    .fadeIn(duration: const Duration(milliseconds: 500)),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
