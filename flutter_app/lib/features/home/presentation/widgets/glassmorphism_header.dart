import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';

class GlassmorphismHeader extends StatelessWidget {
  final double scrollOffset;

  const GlassmorphismHeader({super.key, required this.scrollOffset});

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final opacity = (scrollOffset / 200).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.fromLTRB(20, statusBarHeight + 12, 20, 16),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E2E).withOpacity(opacity),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(opacity * 0.1),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: opacity * 20,
            sigmaY: opacity * 20,
          ),
          child: Row(
            children: [
              // Greeting & Profile
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'DonghuaHub',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Notification Icon
              IconButton(
                onPressed: () {},
                icon: Stack(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.textPrimary,
                      size: 28,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 4),

              // Search Icon
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.search_rounded,
                  color: AppTheme.textPrimary,
                  size: 28,
                ),
              ),

              SizedBox(width: 4),

              // Profile Avatar
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      'U',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: Duration(milliseconds: 400))
        .slideY(begin: -0.2, end: 0, duration: Duration(milliseconds: 400));
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 👋';
    if (hour < 17) return 'Good Afternoon ☀️';
    if (hour < 21) return 'Good Evening 🌅';
    return 'Good Night 🌙';
  }
}
