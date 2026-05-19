import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/local/app_database.dart';
import '../models/account_model.dart';

class AccountRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<AccountModel>> getAll() async {
    final db = await _db;

    final rows = await db.query(
      'accounts',
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );

    return rows.map(AccountModel.fromMap).toList();
  }

  Future<int> insert({
    required String name,
    required double openingBalance,
    required Color color,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();

    return db.insert('accounts', {
      'name': name.trim(),
      'opening_balance': openingBalance,
      'current_balance': openingBalance,
      'icon_code_point': Icons.account_balance_wallet_rounded.codePoint,
      'color_value': color.value,
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(AccountModel model) async {
    if (model.id == null) return 0;

    final db = await _db;
    final now = DateTime.now().toIso8601String();

    return db.update(
      'accounts',
      {
        'name': model.name.trim(),
        'opening_balance': model.openingBalance,
        'current_balance': model.currentBalance,
        'icon_code_point': model.iconCodePoint,
        'color_value': model.colorValue,
        'is_active': model.isActive ? 1 : 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<int> deactivate(int id) async {
    final db = await _db;

    return db.update(
      'accounts',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
