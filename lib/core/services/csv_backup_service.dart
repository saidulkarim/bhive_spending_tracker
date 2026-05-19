import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/local/app_database.dart';

class CsvBackupResult {
  const CsvBackupResult({
    required this.success,
    required this.message,
    this.filePath,
  });

  final bool success;
  final String message;
  final String? filePath;
}

class CsvBackupService {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<CsvBackupResult> exportBackup() async {
    try {
      final db = await _db;

      final accounts = await db.query('accounts', orderBy: 'id ASC');
      final categories = await db.query('categories', orderBy: 'id ASC');
      final transactions = await db.query('transactions', orderBy: 'id ASC');

      final csvRows = <List<dynamic>>[
        ['section', 'json_data'],
        ['metadata', jsonEncode({
          'backup_version': 1,
          'created_at': DateTime.now().toIso8601String(),
        })],
        ['accounts', jsonEncode(accounts)],
        ['categories', jsonEncode(categories)],
        ['transactions', jsonEncode(transactions)],
      ];

      final csvText = const ListToCsvConverter().convert(csvRows);

      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/spending_tracker_backups');

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');

      final file = File('${backupDir.path}/spending_tracker_backup_$timestamp.csv');

      await file.writeAsString(csvText, encoding: utf8);

      await db.insert(
        'backup_logs',
        {
          'backup_type': 'csv_export',
          'file_path': file.path,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return CsvBackupResult(
        success: true,
        message: 'Backup exported successfully.',
        filePath: file.path,
      );
    } catch (e) {
      return CsvBackupResult(
        success: false,
        message: 'Backup failed: $e',
      );
    }
  }

  Future<CsvBackupResult> importBackup() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (picked == null || picked.files.single.path == null) {
        return const CsvBackupResult(
          success: false,
          message: 'No backup file selected.',
        );
      }

      final file = File(picked.files.single.path!);
      final csvText = await file.readAsString(encoding: utf8);

      final rows = const CsvToListConverter(
        shouldParseNumbers: false,
      ).convert(csvText);

      if (rows.length < 2) {
        return const CsvBackupResult(
          success: false,
          message: 'Invalid backup file.',
        );
      }

      final Map<String, String> sections = {};

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length >= 2) {
          sections[row[0].toString()] = row[1].toString();
        }
      }

      final accountsJson = sections['accounts'];
      final categoriesJson = sections['categories'];
      final transactionsJson = sections['transactions'];

      if (accountsJson == null || categoriesJson == null || transactionsJson == null) {
        return const CsvBackupResult(
          success: false,
          message: 'Backup file missing required sections.',
        );
      }

      final accounts = (jsonDecode(accountsJson) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final categories = (jsonDecode(categoriesJson) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final transactions = (jsonDecode(transactionsJson) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final db = await _db;

      await db.transaction<void>((txn) async {
        await txn.delete('transactions');
        await txn.delete('categories');
        await txn.delete('accounts');

        for (final row in accounts) {
          await txn.insert(
            'accounts',
            _sanitizeAccount(row),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        for (final row in categories) {
          await txn.insert(
            'categories',
            _sanitizeCategory(row),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        for (final row in transactions) {
          await txn.insert(
            'transactions',
            _sanitizeTransaction(row),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await txn.insert(
          'backup_logs',
          {
            'backup_type': 'csv_import',
            'file_path': file.path,
            'created_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });

      return CsvBackupResult(
        success: true,
        message: 'Backup restored successfully.',
        filePath: file.path,
      );
    } catch (e) {
      return CsvBackupResult(
        success: false,
        message: 'Restore failed: $e',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getBackupLogs() async {
    final db = await _db;

    return db.query(
      'backup_logs',
      orderBy: 'created_at DESC',
      limit: 20,
    );
  }

  Map<String, dynamic> _sanitizeAccount(Map<String, dynamic> row) {
    return {
      'id': _toInt(row['id']),
      'name': row['name']?.toString() ?? '',
      'opening_balance': _toDouble(row['opening_balance']),
      'current_balance': _toDouble(row['current_balance']),
      'icon_code_point': _toInt(row['icon_code_point'], fallback: 59450),
      'color_value': _toInt(row['color_value'], fallback: 4287311400),
      'is_active': _toInt(row['is_active'], fallback: 1),
      'created_at': row['created_at']?.toString(),
      'updated_at': row['updated_at']?.toString(),
    };
  }

  Map<String, dynamic> _sanitizeCategory(Map<String, dynamic> row) {
    return {
      'id': _toInt(row['id']),
      'name': row['name']?.toString() ?? '',
      'type': row['type']?.toString() ?? 'expense',
      'icon_code_point': _toInt(row['icon_code_point']),
      'color_value': _toInt(row['color_value']),
      'is_active': _toInt(row['is_active'], fallback: 1),
      'created_at': row['created_at']?.toString(),
      'updated_at': row['updated_at']?.toString(),
    };
  }

  Map<String, dynamic> _sanitizeTransaction(Map<String, dynamic> row) {
    return {
      'id': _toInt(row['id']),
      'type': row['type']?.toString() ?? 'expense',
      'amount': _toDouble(row['amount']),
      'category_id': _toInt(row['category_id']),
      'account_id': _toInt(row['account_id']),
      'transaction_date': row['transaction_date']?.toString() ?? DateTime.now().toIso8601String(),
      'note': row['note']?.toString(),
      'created_at': row['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      'updated_at': row['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
    };
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  double _toDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }
}
