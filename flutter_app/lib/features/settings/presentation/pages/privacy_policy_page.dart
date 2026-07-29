import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';

class PrivacyPolicyPage extends ConsumerWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ).animate().fadeIn(duration: Duration(milliseconds: 400)),

            SizedBox(height: 8),

            Text(
              'Last updated: January 2024',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textHint,
              ),
            ),

            SizedBox(height: 24),

            _buildSection(
              'Information We Collect',
              'We collect information you provide directly to us, such as when you create an account, update your profile, or contact us for support. This may include your name, email address, and profile picture.',
            ),

            _buildSection(
              'How We Use Your Information',
              'We use the information we collect to provide, maintain, and improve our services, to personalize your experience, to send you notifications about new episodes and features, and to communicate with you.',
            ),

            _buildSection(
              'Data Storage',
              'Your data is stored securely in our encrypted databases. We use industry-standard security measures to protect your personal information from unauthorized access.',
            ),

            _buildSection(
              'Third-Party Services',
              'We use Clerk for authentication and may use analytics services to improve our app. These services have their own privacy policies that govern their use of your information.',
            ),

            _buildSection(
              'Cookies and Tracking',
              'We use cookies and similar technologies to maintain your session, remember your preferences, and analyze usage patterns. You can control cookie settings through your browser.',
            ),

            _buildSection(
              'Data Sharing',
              'We do not sell or share your personal information with third parties for marketing purposes. We may share anonymized, aggregated data for analytics purposes.',
            ),

            _buildSection(
              'Your Rights',
              'You have the right to access, correct, or delete your personal information. You can also opt out of certain communications and control your privacy settings within the app.',
            ),

            _buildSection(
              'Children\'s Privacy',
              'Our service is not intended for children under 13. We do not knowingly collect personal information from children under 13.',
            ),

            _buildSection(
              'Changes to This Policy',
              'We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy in the app and updating the "Last updated" date.',
            ),

            _buildSection(
              'Contact Us',
              'If you have any questions about this privacy policy, please contact us at privacy@donghuahub.com',
            ),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: Duration(milliseconds: 400));
  }
}
