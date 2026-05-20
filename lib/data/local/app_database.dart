import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static final String _databaseName = 'spending_tracker.db';
  static final int _databaseVersion = 2;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    return _database!;
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _ensureSchema(db);
  }

  Future<void> _onCreate(Database db, int version) async {
    await _ensureSchema(db);
    await _insertSeedData(db);
  }

  Future<void> _ensureSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        opening_balance REAL NOT NULL DEFAULT 0,
        current_balance REAL NOT NULL DEFAULT 0,
        icon_code_point INTEGER NOT NULL DEFAULT 59450,
        color_value INTEGER NOT NULL DEFAULT 4287311400,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_code_point INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category_id INTEGER NOT NULL,
        account_id INTEGER NOT NULL,
        transaction_date TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS backup_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        backup_type TEXT NOT NULL,
        file_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await _addColumnIfMissing(db, 'accounts', 'opening_balance', 'REAL NOT NULL DEFAULT 0');
    await _addColumnIfMissing(db, 'accounts', 'current_balance', 'REAL NOT NULL DEFAULT 0');
    await _addColumnIfMissing(db, 'accounts', 'icon_code_point', 'INTEGER NOT NULL DEFAULT 59450');
    await _addColumnIfMissing(db, 'accounts', 'color_value', 'INTEGER NOT NULL DEFAULT 4287311400');
    await _addColumnIfMissing(db, 'accounts', 'is_active', 'INTEGER NOT NULL DEFAULT 1');
    await _addColumnIfMissing(db, 'accounts', 'created_at', 'TEXT');
    await _addColumnIfMissing(db, 'accounts', 'updated_at', 'TEXT');
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);

    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  Future<void> _insertSeedData(Database db) async {
    final accountCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM accounts'),
        ) ??
        0;

    final categoryCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM categories'),
        ) ??
        0;

    final now = DateTime.now().toIso8601String();

    if (accountCount == 0) {
      final accounts = [
        {
          'name': 'Cash',
          'opening_balance': 0.0,
          'current_balance': 0.0,
          'icon_code_point': Icons.payments_rounded.codePoint,
          'color_value': 0xFF2FA866,
          'created_at': now,
          'updated_at': now,
        },
        {
          'name': 'bKash',
          'opening_balance': 0.0,
          'current_balance': 0.0,
          'icon_code_point': Icons.account_balance_wallet_rounded.codePoint,
          'color_value': 0xFFE05B8B,
          'created_at': now,
          'updated_at': now,
        },
        {
          'name': 'Bank',
          'opening_balance': 0.0,
          'current_balance': 0.0,
          'icon_code_point': Icons.account_balance_rounded.codePoint,
          'color_value': 0xFF5B8DEF,
          'created_at': now,
          'updated_at': now,
        },
      ];

      for (final account in accounts) {
        await db.insert('accounts', account);
      }
    }

    if (categoryCount == 0) {
      final expenseCategories = [
        ['Food', Icons.restaurant_rounded.codePoint, 0xFFE6A23C],
        ['Transport', Icons.directions_bus_rounded.codePoint, 0xFF5B8DEF],
        ['Shopping', Icons.shopping_bag_rounded.codePoint, 0xFFA85B3A],
        ['Bills', Icons.receipt_long_rounded.codePoint, 0xFF9D877D],
        ['Health', Icons.local_hospital_rounded.codePoint, 0xFFE05B5B],
        ['Education', Icons.school_rounded.codePoint, 0xFF2FA866],
        ['Family', Icons.groups_rounded.codePoint, 0xFFB26AE8],
        ['Other', Icons.category_rounded.codePoint, 0xFF8B4428],
      ];

      final incomeCategories = [
        ['Salary', Icons.trending_up_rounded.codePoint, 0xFF2FA866],
        ['Business', Icons.business_center_rounded.codePoint, 0xFF5B8DEF],
        ['Freelance', Icons.laptop_mac_rounded.codePoint, 0xFFE6A23C],
        ['Bonus', Icons.card_giftcard_rounded.codePoint, 0xFFA85B3A],
        ['Other Income', Icons.add_card_rounded.codePoint, 0xFF8B4428],
      ];

      for (final c in expenseCategories) {
        await db.insert('categories', {
          'name': c[0],
          'type': 'expense',
          'icon_code_point': c[1],
          'color_value': c[2],
          'created_at': now,
          'updated_at': now,
        });
      }

      for (final c in incomeCategories) {
        await db.insert('categories', {
          'name': c[0],
          'type': 'income',
          'icon_code_point': c[1],
          'color_value': c[2],
          'created_at': now,
          'updated_at': now,
        });
      }
    }
  }
}
