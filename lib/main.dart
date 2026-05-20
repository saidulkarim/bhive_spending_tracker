import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/localization/app_language_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_controller.dart';
import 'data/local/app_database.dart';
import 'features/auth/presentation/passcode_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppDatabase.instance.database;
  await AppThemeController.instance.load();
  await AppLanguageController.instance.load();

  runApp(SpendingTrackerApp());
}

class SpendingTrackerApp extends StatefulWidget {
  const SpendingTrackerApp({super.key});

  @override
  State<SpendingTrackerApp> createState() => _SpendingTrackerAppState();
}

class _SpendingTrackerAppState extends State<SpendingTrackerApp> {
  final AppThemeController _themeController = AppThemeController.instance;
  final AppLanguageController _languageController = AppLanguageController.instance;

  @override
  void initState() {
    super.initState();
    _themeController.addListener(_onChanged);
    _languageController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _themeController.removeListener(_onChanged);
    _languageController.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final selectedTheme = _themeController.themeMode;

    return MaterialApp(
      title: 'bHiVE Wallet',
      debugShowCheckedModeBanner: false,
      locale: _languageController.locale,
      supportedLocales: [
        Locale('en'),
        Locale('bn'),
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.byMode(selectedTheme),
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeController.materialThemeMode,
      home: PasscodeScreen(),
    );
  }
}
