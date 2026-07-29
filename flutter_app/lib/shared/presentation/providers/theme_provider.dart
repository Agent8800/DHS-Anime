import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class ThemeState {
  final Color primaryColor;
  final bool isAmoled;
  final bool isDark;

  ThemeState({
    required this.primaryColor,
    required this.isAmoled,
    required this.isDark,
  });

  ThemeState copyWith({
    Color? primaryColor,
    bool? isAmoled,
    bool? isDark,
  }) {
    return ThemeState(
      primaryColor: primaryColor ?? this.primaryColor,
      isAmoled: isAmoled ?? this.isAmoled,
      isDark: isDark ?? this.isDark,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  final Box _settingsBox;

  ThemeNotifier(this._settingsBox) : super(ThemeState(
    primaryColor: AppTheme.primaryColor,
    isAmoled: false,
    isDark: true,
  )) {
    _loadTheme();
  }

  void _loadTheme() {
    final colorValue = _settingsBox.get(AppConstants.primaryColorKey);
    final isAmoled = _settingsBox.get(AppConstants.amoledModeKey, defaultValue: false);

    state = state.copyWith(
      primaryColor: colorValue != null ? Color(colorValue) : AppTheme.primaryColor,
      isAmoled: isAmoled,
    );
  }

  void setPrimaryColor(Color color) {
    _settingsBox.put(AppConstants.primaryColorKey, color.value);
    state = state.copyWith(primaryColor: color);
  }

  void toggleAmoled(bool value) {
    _settingsBox.put(AppConstants.amoledModeKey, value);
    state = state.copyWith(isAmoled: value);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  final settingsBox = Hive.box(AppConstants.settingsBox);
  return ThemeNotifier(settingsBox);
});
