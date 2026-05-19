import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/csv_backup_service.dart';
import '../../../core/theme/app_colors.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final CsvBackupService _backupService = CsvBackupService();

  bool _busy = false;
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await _backupService.getBackupLogs();

    if (!mounted) return;

    setState(() {
      _logs = logs;
    });
  }

  Future<void> _exportBackup() async {
    if (_busy) return;

    setState(() => _busy = true);

    final result = await _backupService.exportBackup();

    if (!mounted) return;

    setState(() => _busy = false);

    await _loadLogs();

    _showMessage(result.message);

    if (result.filePath != null) {
      _showBackupPath(result.filePath!);
    }
  }

  Future<void> _restoreBackup() async {
    if (_busy) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Restore backup?'),
          content: const Text(
            'Current accounts, categories, and transactions will be replaced by the selected backup file.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Restore'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _busy = true);

    final result = await _backupService.importBackup();

    if (!mounted) return;

    setState(() => _busy = false);

    await _loadLogs();

    _showMessage(result.message);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showBackupPath(String path) {
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

  String _formatDate(String? value) {
    if (value == null || value.trim().isEmpty) return '-';

    final parsed = DateTime.tryParse(value);

    if (parsed == null) return value;

    return DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Backup',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadLogs,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              const _BackupInfoCard(),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      title: 'Export CSV',
                      subtitle: 'Save local backup',
                      icon: Icons.file_upload_rounded,
                      busy: _busy,
                      onTap: _exportBackup,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _ActionButton(
                      title: 'Restore CSV',
                      subtitle: 'Import backup',
                      icon: Icons.restore_rounded,
                      busy: _busy,
                      onTap: _restoreBackup,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              const Text(
                'Backup History',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 14),

              if (_busy)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_logs.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'No backup history yet.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                )
              else
                ..._logs.map((log) {
                  final type = log['backup_type']?.toString() ?? '-';
                  final path = log['file_path']?.toString() ?? '-';
                  final createdAt = log['created_at']?.toString();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.accent.withOpacity(0.18),
                            child: Icon(
                              type.contains('import')
                                  ? Icons.restore_rounded
                                  : Icons.file_upload_rounded,
                              color: AppColors.accentLight,
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  type == 'csv_import'
                                      ? 'CSV Restore'
                                      : 'CSV Export',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(createdAt),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  path,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackupInfoCard extends StatelessWidget {
  const _BackupInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.security_rounded,
            color: AppColors.textPrimary,
            size: 28,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Export your accounts, categories, and transactions as a CSV backup. Restore this file later on this phone or a new phone.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.busy,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
          child: Column(
            children: [
              Icon(
                icon,
                color: AppColors.textPrimary,
                size: 30,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
