import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/presentation/providers/theme_provider.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    final colors = [
      Color(0xFFFF5C38), // Ember (default)
      Color(0xFFE63B4D), // Crimson
      Color(0xFFFFB020), // Gold
      Color(0xFF34C77B), // Emerald
      Color(0xFF2DD4BF), // Teal
      Color(0xFF4C8DFF), // Sky
      Color(0xFF8B7CF7), // Violet
      Color(0xFFFF6B8A), // Rose
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Theme Settings'),
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
            // AMOLED Mode
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.contrast, color: AppTheme.primaryColor),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AMOLED Mode',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pure black background for AMOLED screens',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: themeState.isAmoled,
                    onChanged: (value) {
                      ref.read(themeProvider.notifier).toggleAmoled(value);
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: Duration(milliseconds: 400)),

            SizedBox(height: 30),

            // Theme Color
            Text(
              'Theme Color',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ).animate().fadeIn(duration: Duration(milliseconds: 400)),

            SizedBox(height: 16),

            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: colors.length,
              itemBuilder: (context, index) {
                final color = colors[index];
                final isSelected = themeState.primaryColor.value == color.value;

                return GestureDetector(
                  onTap: () {
                    ref.read(themeProvider.notifier).setPrimaryColor(color);
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Center(
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 28,
                            ),
                          )
                        : null,
                  ),
                ).animate().fadeIn(
                  duration: Duration(milliseconds: 400),
                  delay: Duration(milliseconds: index * 100),
                ).scale(
                  begin: Offset(0.5, 0.5),
                  end: Offset(1, 1),
                  duration: Duration(milliseconds: 400),
                  delay: Duration(milliseconds: index * 100),
                );
              },
            ),

            SizedBox(height: 30),

            // Preview
            Text(
              'Preview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),

            SizedBox(height: 16),

            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // Sample card
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeState.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: themeState.primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: themeState.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.play_arrow, color: Colors.white),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sample Anime Title',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Episode 1 • Hindi',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Sample buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeState.primaryColor,
                          ),
                          child: Text('Primary'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: themeState.primaryColor),
                          ),
                          child: Text('Secondary'),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Sample chips
                  Wrap(
                    spacing: 8,
                    children: ['Action', 'Fantasy', 'Martial Arts'].map((genre) {
                      return Chip(
                        label: Text(genre),
                        backgroundColor: themeState.primaryColor.withOpacity(0.15),
                        labelStyle: TextStyle(color: themeState.primaryColor),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: Duration(milliseconds: 400)),
          ],
        ),
      ),
    );
  }
}
