import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../download/data/download_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _darkMode = true;
  bool _amoledMode = false;
  String _defaultQuality = '1080p';
  String _defaultLanguage = 'Hindi';

  Future<void> _pickDownloadLocation() async {
    final service = ref.read(downloadServiceProvider);
    final selected = await service.showLocationPicker(context);
    if (selected != null) {
      await service.selectLocation(selected);
      if (mounted) setState(() {});
    }
  }

  Future<void> _handleStoragePermission() async {
    final service = ref.read(downloadServiceProvider);
    final granted = await service.hasStorageAccess();
    if (granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage access is already granted')),
        );
      }
      return;
    }
    await service.requestStoragePermission();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ).animate().fadeIn(duration: Duration(milliseconds: 400)),

              SizedBox(height: 16),

              // Account Section
              _buildSection(
                'Account',
                [
                  _buildAccountTile(),
                ],
              ),

              // Appearance Section
              _buildSection(
                'Appearance',
                [
                  _buildNavigationTile(
                    icon: Icons.palette_outlined,
                    title: 'Theme & Colors',
                    subtitle: 'Customize your app appearance',
                    onTap: () => context.push('/settings/theme'),
                  ),
                  _buildSwitchTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    value: _darkMode,
                    onChanged: (value) {
                      setState(() => _darkMode = value);
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.contrast,
                    title: 'AMOLED Mode',
                    subtitle: 'Pure black for AMOLED screens',
                    value: _amoledMode,
                    onChanged: (value) {
                      setState(() => _amoledMode = value);
                    },
                  ),
                ],
              ),

              // Playback Section (offline, built-in player)
              _buildSection(
                'Playback',
                [
                  _buildDropdownTile(
                    icon: Icons.high_quality,
                    title: 'Preferred Download Quality',
                    value: _defaultQuality,
                    items: ['1080p', '720p', '480p', '360p'],
                    onChanged: (value) {
                      setState(() => _defaultQuality = value!);
                    },
                  ),
                  _buildDropdownTile(
                    icon: Icons.translate,
                    title: 'Preferred Language',
                    value: _defaultLanguage,
                    items: ['Hindi', 'English', 'Japanese', 'Chinese'],
                    onChanged: (value) {
                      setState(() => _defaultLanguage = value!);
                    },
                  ),
                ],
              ),

              // Download Section
              _buildSection(
                'Downloads',
                [
                  _buildNavigationTile(
                    icon: Icons.download_outlined,
                    title: 'Download Manager',
                    subtitle: 'Manage your downloads',
                    onTap: () => context.push('/downloads'),
                  ),
                  _buildNavigationTile(
                    icon: Icons.folder_outlined,
                    title: 'Download Location',
                    subtitle: ref.watch(downloadServiceProvider).configuredPath,
                    onTap: _pickDownloadLocation,
                  ),
                  _buildNavigationTile(
                    icon: Icons.sd_storage_outlined,
                    title: 'Storage Permission',
                    subtitle: 'Required for the public DHS Anime folder',
                    onTap: _handleStoragePermission,
                  ),
                  _buildNavigationTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'New episode & new donghua alerts',
                    onTap: () => context.push('/notifications'),
                  ),
                ],
              ),

              // Other Section
              _buildSection(
                'Other',
                [
                  _buildNavigationTile(
                    icon: Icons.delete_outline,
                    title: 'Clear Cache',
                    subtitle: '128 MB cached',
                    onTap: () => _showClearCacheDialog(),
                  ),
                  _buildNavigationTile(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'Version ${AppConstants.appVersion}',
                    onTap: () => context.push('/settings/about'),
                  ),
                  _buildNavigationTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => context.push('/settings/privacy'),
                  ),
                  _buildNavigationTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () {},
                  ),
                ],
              ),

              // Logout
              Padding(
                padding: EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(),
                    icon: Icon(Icons.logout, color: AppTheme.errorColor),
                    label: Text(
                      'Logout',
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.errorColor.withOpacity(0.3)),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: Duration(milliseconds: 400)),

              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    ).animate().fadeIn(duration: Duration(milliseconds: 400));
  }

  Widget _buildAccountTile() {
    final auth = ref.watch(authServiceProvider);
    final displayName = auth.name.isNotEmpty ? auth.name : 'User';
    final displayEmail = auth.email.isNotEmpty ? auth.email : 'Signed in with Google';

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            displayName.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Text(
        displayName,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        displayEmail,
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Free',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      onTap: () => context.push('/settings/account'),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textHint,
              ),
            )
          : null,
      trailing: Icon(Icons.chevron_right, color: AppTheme.textHint),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textHint,
              ),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButton<String>(
          value: value,
          dropdownColor: AppTheme.surfaceColor,
          underline: SizedBox(),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Cache'),
        content: Text('This will clear all cached data. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Sign out of Clerk (Google) and clear the local session
              await ref.read(authServiceProvider.notifier).signOut(context);
              if (mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}
