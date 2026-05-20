import 'package:flutter/material.dart';

import 'app_theme_controller.dart';

class AppColors {
  AppColors._();

  static Color primary = Color(0xFF8B4428);
  static Color primaryDark = Color(0xFF2A130D);

  static Color accent = Color(0xFF8B4428);
  static Color accentLight = Color(0xFFE6A23C);
  static Color accentDark = Color(0xFF5A2818);

  static Color background = Color(0xFF120806);
  static Color surface = Color(0xFF1C0E0A);
  static Color card = Color(0xFF21110C);
  static Color bottomBar = Color(0xFF1A0C08);

  static Color border = Color(0xFF3C2419);

  static Color textPrimary = Color(0xFFF8E7D0);
  static Color textSecondary = Color(0xFFD8BFA7);
  static Color textMuted = Color(0xFF9D877D);

  static Color success = Color(0xFF2FA866);
  static Color danger = Color(0xFFE05B5B);
  static Color warning = Color(0xFFE6A23C);

  static Color bluePrimary = Color(0xFF1565C0);
  static Color blueAccent = Color(0xFF42A5F5);
  static Color blueBackground = Color(0xFFEAF4FF);
  static Color blueSurface = Color(0xFFF7FBFF);
  static Color blueCard = Color(0xFFFFFFFF);

  static Color lightPrimary = Color(0xFF6D3B22);
  static Color lightAccent = Color(0xFFC9822B);
  static Color lightBackground = Color(0xFFFFF8F1);
  static Color lightSurface = Color(0xFFFFFFFF);
  static Color lightCard = Color(0xFFFFFFFF);

  static Color lightTextPrimary = Color(0xFF1F1A17);
  static Color lightTextSecondary = Color(0xFF6F625B);
  static Color lightTextMuted = Color(0xFF998A82);
  static Color lightBorder = Color(0xFFE7D8CB);

  static void applyTheme(AppThemeMode mode, {Brightness? platformBrightness}) {
    switch (mode) {
      case AppThemeMode.lightBlue:
        _applyLightBlue();
        break;
      case AppThemeMode.light:
        _applyLight();
        break;
      case AppThemeMode.systemDark:
        if (platformBrightness == Brightness.light) {
          _applyLight();
        } else {
          _applyDark();
        }
        break;
    }
  }

  static void _applyDark() {
    primary = Color(0xFF8B4428);
    primaryDark = Color(0xFF2A130D);
    accent = Color(0xFF8B4428);
    accentLight = Color(0xFFE6A23C);
    accentDark = Color(0xFF5A2818);
    background = Color(0xFF120806);
    surface = Color(0xFF1C0E0A);
    card = Color(0xFF21110C);
    bottomBar = Color(0xFF1A0C08);
    border = Color(0xFF3C2419);
    textPrimary = Color(0xFFF8E7D0);
    textSecondary = Color(0xFFD8BFA7);
    textMuted = Color(0xFF9D877D);
    success = Color(0xFF2FA866);
    danger = Color(0xFFE05B5B);
    warning = Color(0xFFE6A23C);
  }

  static void _applyLightBlue() {
    primary = Color(0xFF1565C0);
    primaryDark = Color(0xFF0B2C4D);
    accent = Color(0xFF1565C0);
    accentLight = Color(0xFF42A5F5);
    accentDark = Color(0xFF0D47A1);
    background = Color(0xFFEAF4FF);
    surface = Color(0xFFF7FBFF);
    card = Color(0xFFFFFFFF);
    bottomBar = Color(0xFFFFFFFF);
    border = Color(0xFFD9EAF7);
    textPrimary = Color(0xFF102A43);
    textSecondary = Color(0xFF486581);
    textMuted = Color(0xFF829AB1);
    success = Color(0xFF1B8A5A);
    danger = Color(0xFFD64545);
    warning = Color(0xFFB7791F);
  }

  static void _applyLight() {
    primary = Color(0xFF6D3B22);
    primaryDark = Color(0xFF3A2014);
    accent = Color(0xFFC9822B);
    accentLight = Color(0xFFE6A23C);
    accentDark = Color(0xFF8B4428);
    background = Color(0xFFFFF8F1);
    surface = Color(0xFFFFFFFF);
    card = Color(0xFFFFFFFF);
    bottomBar = Color(0xFFFFFFFF);
    border = Color(0xFFE7D8CB);
    textPrimary = Color(0xFF1F1A17);
    textSecondary = Color(0xFF6F625B);
    textMuted = Color(0xFF998A82);
    success = Color(0xFF208A55);
    danger = Color(0xFFC84646);
    warning = Color(0xFFB7791F);
  }
}
