import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: 20),

            // App Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.play_circle_fill_rounded,
                size: 50,
                color: Colors.white,
              ),
            ).animate().fadeIn(duration: Duration(milliseconds: 600)).scale(
              begin: Offset(0.5, 0.5),
              end: Offset(1, 1),
              duration: Duration(milliseconds: 600),
            ),

            SizedBox(height: 20),

            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),

            SizedBox(height: 4),

            Text(
              'Version ${AppConstants.appVersion}',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),

            SizedBox(height: 8),

            Text(
              AppConstants.appDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textHint,
              ),
            ),

            SizedBox(height: 40),

            // Info Cards
            _buildInfoCard(
              icon: Icons.info_outline,
              title: 'About',
              description: 'DonghuaHub is your ultimate destination for streaming and downloading Chinese animated series (Donghua). All content is manually curated by our admin team.',
            ),

            SizedBox(height: 16),

            _buildInfoCard(
              icon: Icons.favorite_outline,
              title: 'Support',
              description: 'If you enjoy using DonghuaHub, please consider supporting us by sharing with your friends and leaving a positive review.',
            ),

            SizedBox(height: 16),

            _buildInfoCard(
              icon: Icons.bug_report_outlined,
              title: 'Report Issues',
              description: 'Found a bug or have a suggestion? Please report it through the app settings or contact us directly.',
            ),

            SizedBox(height: 30),

            // Social Links
            Text(
              'Follow Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),

            SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(Icons.telegram, 'Telegram'),
                SizedBox(width: 16),
                _buildSocialButton(Icons.discord, 'Discord'),
                SizedBox(width: 16),
                _buildSocialButton(Icons.language, 'Website'),
              ],
            ),

            SizedBox(height: 40),

            Text(
              'Made with ❤️ for Donghua fans',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textHint,
              ),
            ),

            SizedBox(height: 8),

            Text(
              '© 2024 DonghuaHub. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textHint,
              ),
            ),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 24),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: Duration(milliseconds: 400));
  }

  Widget _buildSocialButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 28),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
