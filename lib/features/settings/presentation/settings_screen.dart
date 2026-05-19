import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/csv_backup_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/local/app_database.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _pinKey = 'app_pin';
  static const String _lockEnabledKey = 'app_lock_enabled';

  final CsvBackupService _backupService = CsvBackupService();

  bool _loading = true;
  bool _busy = false;
  bool _lockEnabled = true;
  String _versionText = 'Version -';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final info = await PackageInfo.fromPlatform();

    if (!mounted) return;

    setState(() {
      _lockEnabled = prefs.getBool(_lockEnabledKey) ?? true;
      _versionText = 'Version ${info.version}+${info.buildNumber}';
      _loading = false;
    });
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
      shape: const RoundedRectangleBorder(
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
          title: const Text('Clear spending data?'),
          content: const Text(
            'All transactions will be deleted and account current balances will reset to opening balances. Categories and accounts will remain.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Clear'),
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
          title: const Text('Backup Saved'),
          content: SelectableText(
            path,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                children: [
                  _SettingsGroup(
                    title: 'Security',
                    children: [
                      _SwitchTile(
                        icon: Icons.lock_rounded,
                        title: 'App Lock',
                        subtitle: 'Require 4-digit passcode when opening the app.',
                        value: _lockEnabled,
                        onChanged: _busy ? null : _setLockEnabled,
                      ),
                      _ActionTile(
                        icon: Icons.password_rounded,
                        title: 'Change Passcode',
                        subtitle: 'Update your 4-digit security code.',
                        onTap: _busy ? null : _resetPasscode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SettingsGroup(
                    title: 'Backup',
                    children: [
                      _ActionTile(
                        icon: Icons.file_upload_rounded,
                        title: 'Export CSV Backup',
                        subtitle: 'Create a local backup of accounts, categories and transactions.',
                        onTap: _busy ? null : _exportBackup,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SettingsGroup(
                    title: 'Data',
                    children: [
                      _ActionTile(
                        icon: Icons.cleaning_services_rounded,
                        title: 'Clear Transactions',
                        subtitle: 'Delete all transactions and reset current account balances.',
                        danger: true,
                        onTap: _busy ? null : _clearTransactions,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SettingsGroup(
                    title: 'Application',
                    children: [
                      _InfoTile(
                        icon: Icons.info_outline_rounded,
                        title: 'App Version',
                        subtitle: _versionText,
                      ),
                      const _InfoTile(
                        icon: Icons.dark_mode_rounded,
                        title: 'Theme',
                        subtitle: 'Dark theme is currently active.',
                      ),
                    ],
                  ),
                  if (_busy) ...[
                    const SizedBox(height: 24),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
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
  static const String _pinKey = 'app_pin';
  static const String _lockEnabledKey = 'app_lock_enabled';

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
            const SizedBox(height: 22),
            Text(
              widget.isFirstSetup ? 'Create Passcode' : 'Change Passcode',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            if (showOldPin) ...[
              _PinField(controller: _oldPinController, label: 'Current Passcode'),
              const SizedBox(height: 14),
            ],
            _PinField(controller: _newPinController, label: 'New Passcode'),
            const SizedBox(height: 14),
            _PinField(controller: _confirmPinController, label: 'Confirm New Passcode'),
            const SizedBox(height: 24),
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
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
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
  const _PinField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: 4,
      obscureText: true,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(labelText: label, counterText: ''),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
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
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
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
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.25,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
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
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.25,
        ),
      ),
    );
  }
}
