// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_theme_controller.dart';

class AppTheme {
  AppTheme._();

  static String fontFamily = 'Exo2';

  static ThemeData byMode(AppThemeMode mode) {
    AppColors.applyTheme(mode);
    switch (mode) {
      case AppThemeMode.lightBlue:
        return lightBlueTheme;
      case AppThemeMode.light:
        return lightTheme;
      case AppThemeMode.systemDark:
        return darkTheme;
    }
  }

  static ThemeData get lightBlueTheme {
    return _baseTheme(
      seedColor: AppColors.bluePrimary,
      brightness: Brightness.light,
    );
  }

  static ThemeData get lightTheme {
    return _baseTheme(
      seedColor: AppColors.lightPrimary,
      brightness: Brightness.light,
    );
  }

  static ThemeData get darkTheme {
    return _baseTheme(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );
  }

  static ThemeData _baseTheme({
    required Color seedColor,
    required Brightness brightness,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.card,
      dividerColor: AppColors.border,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: fontFamily,
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(
        fontFamily: fontFamily,
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          fontFamily: fontFamily,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: AppColors.background,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent.withOpacity(0.35);
          }
          return null;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: TextStyle(
          color: AppColors.textSecondary,
          fontFamily: fontFamily,
        ),
        hintStyle: TextStyle(
          color: AppColors.textSecondary,
          fontFamily: fontFamily,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.accent, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.dark
            ? AppColors.surface
            : Color(0xFF263238),
        contentTextStyle: TextStyle(
          color: Colors.white,
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
