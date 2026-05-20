import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageController extends ChangeNotifier {
  AppLanguageController._();

  static final AppLanguageController instance = AppLanguageController._();

  static String languageKey = 'selected_language_code';

  String _languageCode = 'en';
  bool _loaded = false;

  String get languageCode => _languageCode;
  bool get loaded => _loaded;
  bool get isBangla => _languageCode == 'bn';
  Locale get locale => Locale(_languageCode);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString(languageKey) ?? 'en';
    if (_languageCode != 'bn') _languageCode = 'en';
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code == 'bn' ? 'bn' : 'en';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(languageKey, _languageCode);
    notifyListeners();
  }

  String text(String en, String bn) => isBangla ? bn : en;
}
