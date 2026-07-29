import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../config/api_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  Box get _settingsBox => Hive.box(AppConstants.settingsBox);

  bool get _isPremium =>
      _settingsBox.get(AppConstants.userIsPremiumKey, defaultValue: false) ==
      true;

  DateTime? get _premiumExpiry {
    final raw =
        _settingsBox.get(AppConstants.userPremiumExpiryKey, defaultValue: '')
            .toString();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  String get _planLabel {
    if (!_isPremium) return 'Free';
    final expiry = _premiumExpiry;
    if (expiry == null) return 'Premium';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return 'Premium · till ${expiry.day} ${months[expiry.month - 1]}';
  }

  Future<void> _openRedeemSheet() async {
    final activated = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _RedeemPremiumSheet(),
    );

    if (activated == true && mounted) {
      setState(() {}); // re-read premium state from Hive
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Premium activated — enjoy!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authServiceProvider);
    final name = auth.name.isNotEmpty ? auth.name : 'User';
    final email = auth.email;
    final initial =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Section
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: (_isPremium
                              ? const Color(0xFF3ECF8E)
                              : AppTheme.textHint)
                          .withOpacity(0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _planLabel,
                      style: TextStyle(
                        color: _isPremium
                            ? const Color(0xFF3ECF8E)
                            : AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: Duration(milliseconds: 400)),

            SizedBox(height: 20),

            // Premium banner
            _isPremium ? _buildPremiumActiveBanner() : _buildGoPremiumBanner(),

            SizedBox(height: 20),

            // Devices
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registered Devices',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildDeviceTile('Android Phone', 'Last active: Just now', true),
                  _buildDeviceTile('iPad Pro', 'Last active: 2 hours ago', false),
                  _buildDeviceTile('Web Browser', 'Last active: Yesterday', false),
                ],
              ),
            ).animate().fadeIn(duration: Duration(milliseconds: 400)),
          ],
        ),
      ),
    );
  }

  Widget _buildGoPremiumBanner() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.accentColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.diamond, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Go Premium',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Free users solve a shortener before each download. Premium skips it — downloads start instantly.',
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _openRedeemSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Activate with Code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: Duration(milliseconds: 400));
  }

  Widget _buildPremiumActiveBanner() {
    final expiry = _premiumExpiry;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final expiryText = expiry == null
        ? 'Shorteners skipped on every download'
        : 'Valid till ${expiry.day} ${months[expiry.month - 1]} ${expiry.year}';

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E9E6A), Color(0xFF3ECF8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3ECF8E).withOpacity(0.25),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.verified_rounded, color: Colors.white, size: 26),
              SizedBox(width: 12),
              Text(
                'Premium Active',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '$expiryText • no shorteners',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _openRedeemSheet,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.7)),
                padding: EdgeInsets.symmetric(vertical: 13),
              ),
              child: const Text(
                'Extend with Code',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: Duration(milliseconds: 400));
  }

  Widget _buildDeviceTile(String name, String lastActive, bool isCurrent) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppTheme.primaryColor.withOpacity(0.1)
            : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: isCurrent
            ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          Icon(
            name.contains('Android')
                ? Icons.android
                : name.contains('iPad')
                    ? Icons.tablet_mac
                    : Icons.computer,
            color: isCurrent ? AppTheme.primaryColor : AppTheme.textSecondary,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (isCurrent) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Current',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  lastActive,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ),
          if (!isCurrent)
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: AppTheme.errorColor),
              onPressed: () {},
            ),
        ],
      ),
    );
  }
}

/// Redeem a dev-generated premium activation code (single use, stacks
/// with an active period).
class _RedeemPremiumSheet extends StatefulWidget {
  const _RedeemPremiumSheet();

  @override
  State<_RedeemPremiumSheet> createState() => _RedeemPremiumSheetState();
}

class _RedeemPremiumSheetState extends State<_RedeemPremiumSheet> {
  final TextEditingController _codeController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Enter your activation code');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: AppConstants.tokenKey);
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      ));

      final response = await dio.post(
        '${ApiConfig.auth}/redeem-premium',
        data: {'code': code},
      );

      final data = response.data['data'] as Map<String, dynamic>? ?? {};

      // Persist locally so the whole app sees premium immediately
      final box = Hive.box(AppConstants.settingsBox);
      await box.put(AppConstants.userIsPremiumKey, true);
      await box.put(
        AppConstants.userPremiumExpiryKey,
        data['premiumExpiry']?.toString() ?? '',
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.response?.data is Map
          ? (e.response!.data['message']?.toString() ??
              e.response!.data['error']?.toString())
          : null;
      setState(() {
        _submitting = false;
        _error = message ?? 'Could not redeem code. Check your connection.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not redeem code. Check your connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.diamond_outlined,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activate Premium',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Codes are shared by the developer',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
                LengthLimitingTextInputFormatter(19),
              ],
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'DHS-XXXXXX-XXXXXX',
                hintStyle: TextStyle(
                  color: AppTheme.textHint.withOpacity(0.5),
                  letterSpacing: 1.5,
                ),
                filled: true,
                fillColor: AppTheme.cardColor,
                prefixIcon: const Icon(Icons.vpn_key_outlined,
                    color: AppTheme.textHint, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                errorText: _error,
              ),
              onSubmitted: (_) => _redeem(),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _redeem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Activate',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
