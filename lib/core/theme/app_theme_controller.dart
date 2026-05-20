import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

enum AppThemeMode {
  lightBlue,
  systemDark,
  light,
}

extension AppThemeModeX on AppThemeMode {
  String get key {
    switch (this) {
      case AppThemeMode.lightBlue:
        return 'light_blue';
      case AppThemeMode.systemDark:
        return 'system_dark';
      case AppThemeMode.light:
        return 'light';
    }
  }

  String get title {
    switch (this) {
      case AppThemeMode.lightBlue:
        return 'Light Blue';
      case AppThemeMode.systemDark:
        return 'System / Dark';
      case AppThemeMode.light:
        return 'Light';
    }
  }

  String get bnTitle {
    switch (this) {
      case AppThemeMode.lightBlue:
        return 'লাইট ব্লু';
      case AppThemeMode.systemDark:
        return 'সিস্টেম / ডার্ক';
      case AppThemeMode.light:
        return 'লাইট';
    }
  }

  String get subtitle {
    switch (this) {
      case AppThemeMode.lightBlue:
        return 'Clean blue finance style';
      case AppThemeMode.systemDark:
        return 'Use system mode, with premium dark theme';
      case AppThemeMode.light:
        return 'Warm clean light theme';
    }
  }

  String get bnSubtitle {
    switch (this) {
      case AppThemeMode.lightBlue:
        return 'পরিষ্কার নীল ফাইন্যান্স স্টাইল';
      case AppThemeMode.systemDark:
        return 'সিস্টেম মোড, প্রিমিয়াম ডার্ক থিমসহ';
      case AppThemeMode.light:
        return 'উষ্ণ ও পরিষ্কার লাইট থিম';
    }
  }

  static AppThemeMode fromKey(String? key) {
    switch (key) {
      case 'light_blue':
        return AppThemeMode.lightBlue;
      case 'light':
        return AppThemeMode.light;
      case 'system_dark':
      default:
        return AppThemeMode.systemDark;
    }
  }
}

class AppThemeController extends ChangeNotifier {
  AppThemeController._();

  static final AppThemeController instance = AppThemeController._();

  static String themeKey = 'selected_theme_mode';

  AppThemeMode _themeMode = AppThemeMode.systemDark;
  bool _loaded = false;

  AppThemeMode get themeMode => _themeMode;
  bool get loaded => _loaded;

  ThemeMode get materialThemeMode {
    switch (_themeMode) {
      case AppThemeMode.lightBlue:
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.systemDark:
        return ThemeMode.system;
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = AppThemeModeX.fromKey(prefs.getString(themeKey));
    AppColors.applyTheme(_themeMode);
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    AppColors.applyTheme(_themeMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themeKey, mode.key);
    notifyListeners();
  }
}
