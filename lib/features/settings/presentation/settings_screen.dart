// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/localization/app_language_controller.dart';
import '../../../core/localization/app_text.dart';
import '../../../core/services/csv_backup_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_controller.dart';
import '../../../data/local/app_database.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static final String _pinKey = 'app_pin';
  static final String _lockEnabledKey = 'app_lock_enabled';

  final CsvBackupService _backupService = CsvBackupService();
  final AppThemeController _themeController = AppThemeController.instance;
  final AppLanguageController _languageController = AppLanguageController.instance;

  bool _loading = true;
  bool _busy = false;
  bool _lockEnabled = true;
  String _versionText = 'Version -';

  @override
  void initState() {
    super.initState();
    _themeController.addListener(_onThemeChanged);
    _languageController.addListener(_onLanguageChanged);
    _loadSettings();
  }

  @override
  void dispose() {
    _themeController.removeListener(_onThemeChanged);
    _languageController.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final info = await PackageInfo.fromPlatform();

    if (!_themeController.loaded) {
      await _themeController.load();
    }

    if (!_languageController.loaded) {
      await _languageController.load();
    }

    if (!mounted) return;

    setState(() {
      _lockEnabled = prefs.getBool(_lockEnabledKey) ?? true;
      _versionText = 'Version ${info.version}+${info.buildNumber}';
      _loading = false;
    });
  }

  Future<void> _setTheme(AppThemeMode mode) async {
    await _themeController.setThemeMode(mode);

    if (!mounted) return;

    _showMessage(AppText.tr('${mode.title} theme selected.', '${mode.bnTitle} থিম নির্বাচন করা হয়েছে।'));
  }

  Future<void> _setLanguage(String code) async {
    await _languageController.setLanguage(code);

    if (!mounted) return;

    _showMessage(AppText.tr('Language changed to English.', 'ভাষা বাংলা করা হয়েছে।'));
  }

  Future<void> _setLockEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(_pinKey);

    if (value && savedPin == null) {
      final created = await _showChangePasscodeSheet(isFirstSetup: true);
      if (created != true) return;
    }

    await prefs.setBool(_lockEnabledKey, value);

    if (!mounted) return;

    setState(() => _lockEnabled = value);
    _showMessage(value ? 'App lock enabled.' : 'App lock disabled.');
  }

  Future<bool?> _showChangePasscodeSheet({bool isFirstSetup = false}) async {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return _ChangePasscodeSheet(
          isFirstSetup: isFirstSetup,
          onSaved: _loadSettings,
        );
      },
    );
  }

  Future<void> _resetPasscode() async {
    final result = await _showChangePasscodeSheet();

    if (result == true && mounted) {
      _showMessage('Passcode updated successfully.');
    }
  }

  Future<void> _exportBackup() async {
    if (_busy) return;

    setState(() => _busy = true);

    final result = await _backupService.exportBackup();

    if (!mounted) return;

    setState(() => _busy = false);

    _showMessage(result.message);

    if (result.filePath != null) {
      _showPathDialog(result.filePath!);
    }
  }

  Future<void> _clearTransactions() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Clear spending data?'),
          content: Text(
            'All transactions will be deleted and account current balances will reset to opening balances. Categories and accounts will remain.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Yes, Clear'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _busy = true);

    final db = await AppDatabase.instance.database;

    await db.transaction<void>((txn) async {
      await txn.delete('transactions');
      await txn.rawUpdate(
        'UPDATE accounts SET current_balance = opening_balance, updated_at = ?',
        [DateTime.now().toIso8601String()],
      );
    });

    if (!mounted) return;

    setState(() => _busy = false);
    _showMessage('Transactions cleared successfully.');
  }

  void _showPathDialog(String path) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Backup Saved'),
          content: SelectableText(
            path,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedTheme = _themeController.themeMode;
    final selectedLanguage = _languageController.languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(AppText.tr('Settings', 'সেটিংস'))),
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 110),
                children: [
                  _SettingsGroup(
                    title: AppText.tr('Appearance', 'অ্যাপিয়ারেন্স'),
                    children: [
                      _ThemeTile(
                        mode: AppThemeMode.lightBlue,
                        selectedMode: selectedTheme,
                        icon: Icons.water_drop_rounded,
                        color: AppColors.bluePrimary,
                        onTap: _setTheme,
                      ),
                      _ThemeTile(
                        mode: AppThemeMode.systemDark,
                        selectedMode: selectedTheme,
                        icon: Icons.dark_mode_rounded,
                        color: AppColors.accent,
                        onTap: _setTheme,
                      ),
                      _ThemeTile(
                        mode: AppThemeMode.light,
                        selectedMode: selectedTheme,
                        icon: Icons.light_mode_rounded,
                        color: AppColors.lightAccent,
                        onTap: _setTheme,
                      ),
                    ],
                  ),

                  SizedBox(height: 18),

                  _SettingsGroup(
                    title: AppText.tr('Language', 'ভাষা'),
                    children: [
                      _LanguageTile(
                        code: 'en',
                        title: 'English',
                        subtitle: 'Use English language',
                        selectedCode: selectedLanguage,
                        iconText: 'EN',
                        onTap: _setLanguage,
                      ),
                      _LanguageTile(
                        code: 'bn',
                        title: 'বাংলা',
                        subtitle: 'বাংলা ভাষা ব্যবহার করুন',
                        selectedCode: selectedLanguage,
                        iconText: 'বাং',
                        onTap: _setLanguage,
                      ),
                    ],
                  ),

                  SizedBox(height: 18),

                  _SettingsGroup(
                    title: AppText.tr('Security', 'নিরাপত্তা'),
                    children: [
                      _SwitchTile(
                        icon: Icons.lock_rounded,
                        title: AppText.tr('App Lock', 'অ্যাপ লক'),
                        subtitle:
                            AppText.tr('Require 4-digit passcode when opening the app.', 'অ্যাপ চালু করার সময় ৪ ডিজিটের পাসকোড চাইবে।'),
                        value: _lockEnabled,
                        onChanged: _busy ? null : _setLockEnabled,
                      ),
                      _ActionTile(
                        icon: Icons.password_rounded,
                        title: AppText.tr('Change Passcode', 'পাসকোড পরিবর্তন'),
                        subtitle: AppText.tr('Update your 4-digit security code.', 'আপনার ৪ ডিজিটের নিরাপত্তা কোড পরিবর্তন করুন।'),
                        onTap: _busy ? null : _resetPasscode,
                      ),
                    ],
                  ),

                  SizedBox(height: 18),

                  _SettingsGroup(
                    title: AppText.tr('Backup', 'ব্যাকআপ'),
                    children: [
                      _ActionTile(
                        icon: Icons.file_upload_rounded,
                        title: AppText.tr('Export CSV Backup', 'CSV ব্যাকআপ এক্সপোর্ট'),
                        subtitle:
                            AppText.tr('Create a local backup of accounts, categories and transactions.', 'অ্যাকাউন্ট, ক্যাটাগরি এবং লেনদেনের লোকাল ব্যাকআপ তৈরি করুন।'),
                        onTap: _busy ? null : _exportBackup,
                      ),
                    ],
                  ),

                  SizedBox(height: 18),

                  _SettingsGroup(
                    title: AppText.tr('Data', 'ডাটা'),
                    children: [
                      _ActionTile(
                        icon: Icons.cleaning_services_rounded,
                        title: AppText.tr('Clear Transactions', 'লেনদেন মুছুন'),
                        subtitle:
                            AppText.tr('Delete all transactions and reset current account balances.', 'সব লেনদেন মুছে বর্তমান অ্যাকাউন্ট ব্যালেন্স রিসেট করুন।'),
                        danger: true,
                        onTap: _busy ? null : _clearTransactions,
                      ),
                    ],
                  ),

                  SizedBox(height: 18),

                  _SettingsGroup(
                    title: AppText.tr('Application', 'অ্যাপ্লিকেশন'),
                    children: [
                      _InfoTile(
                        icon: Icons.info_outline_rounded,
                        title: AppText.tr('App Version', 'অ্যাপ ভার্সন'),
                        subtitle: _versionText,
                      ),
                      _InfoTile(
                        icon: Icons.font_download_rounded,
                        title: AppText.tr('Default Font', 'ডিফল্ট ফন্ট'),
                        subtitle: 'Exo 2',
                      ),
                    ],
                  ),

                  if (_busy) ...[
                    SizedBox(height: 24),
                    Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
      ),
    );
  }
}


class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.selectedCode,
    required this.iconText,
    required this.onTap,
  });

  final String code;
  final String title;
  final String subtitle;
  final String selectedCode;
  final String iconText;
  final Future<void> Function(String code) onTap;

  @override
  Widget build(BuildContext context) {
    final selected = code == selectedCode;

    return ListTile(
      onTap: () => onTap(code),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.accent.withOpacity(0.16),
        child: Text(
          iconText,
          style: TextStyle(
            color: AppColors.accent,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.25,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: AppColors.success)
          : Icon(Icons.circle_outlined, color: AppColors.textMuted),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.mode,
    required this.selectedMode,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final AppThemeMode mode;
  final AppThemeMode selectedMode;
  final IconData icon;
  final Color color;
  final Future<void> Function(AppThemeMode mode) onTap;

  @override
  Widget build(BuildContext context) {
    final selected = mode == selectedMode;

    return ListTile(
      onTap: () => onTap(mode),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: color.withOpacity(0.16),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        AppText.tr(mode.title, mode.bnTitle),
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        AppText.tr(mode.subtitle, mode.bnSubtitle),
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.25,
        ),
      ),
      trailing: selected
          ? Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
            )
          : Icon(
              Icons.circle_outlined,
              color: AppColors.textMuted,
            ),
    );
  }
}

class _ChangePasscodeSheet extends StatefulWidget {
  const _ChangePasscodeSheet({
    required this.isFirstSetup,
    required this.onSaved,
  });

  final bool isFirstSetup;
  final Future<void> Function() onSaved;

  @override
  State<_ChangePasscodeSheet> createState() => _ChangePasscodeSheetState();
}

class _ChangePasscodeSheetState extends State<_ChangePasscodeSheet> {
  static final String _pinKey = 'app_pin';
  static final String _lockEnabledKey = 'app_lock_enabled';

  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _saving = false;
  bool _hasExistingPin = false;

  @override
  void initState() {
    super.initState();
    _checkExistingPin();
  }

  Future<void> _checkExistingPin() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _hasExistingPin = prefs.getString(_pinKey) != null;
    });
  }

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;

    final oldPin = _oldPinController.text.trim();
    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (newPin.length != 4 || int.tryParse(newPin) == null) {
      _showMessage('New passcode must be exactly 4 digits.');
      return;
    }

    if (newPin != confirmPin) {
      _showMessage('Confirm passcode did not match.');
      return;
    }

    setState(() => _saving = true);

    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(_pinKey);

    if (!widget.isFirstSetup && savedPin != null && oldPin != savedPin) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Current passcode is incorrect.');
      return;
    }

    await prefs.setString(_pinKey, newPin);
    await prefs.setBool(_lockEnabledKey, true);
    await widget.onSaved();

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showOldPin = _hasExistingPin && !widget.isFirstSetup;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            SizedBox(height: 22),
            Text(
              widget.isFirstSetup ? 'Create Passcode' : AppText.tr('Change Passcode', 'পাসকোড পরিবর্তন'),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 18),
            if (showOldPin) ...[
              _PinField(
                controller: _oldPinController,
                label: 'Current Passcode',
              ),
              SizedBox(height: 14),
            ],
            _PinField(
              controller: _newPinController,
              label: 'New Passcode',
            ),
            SizedBox(height: 14),
            _PinField(
              controller: _confirmPinController,
              label: 'Confirm New Passcode',
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.save_rounded),
                label: Text(_saving ? 'Saving...' : 'Save Passcode'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: 4,
      obscureText: true,
      keyboardType: TextInputType.number,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border, width: 0.7),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.accentLight,
      secondary: Icon(icon, color: AppColors.textPrimary),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.25,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.textPrimary;

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.25,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.25,
        ),
      ),
    );
  }
}
