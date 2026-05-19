import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/local/app_database.dart';
import 'features/auth/presentation/passcode_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.database;
  runApp(const SpendingTrackerApp());
}

class SpendingTrackerApp extends StatelessWidget {
  const SpendingTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spending Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const PasscodeScreen(),
    );
  }
}
