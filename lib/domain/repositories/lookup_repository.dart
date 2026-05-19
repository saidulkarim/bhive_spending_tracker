import 'package:sqflite/sqflite.dart';

import '../../data/local/app_database.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';

class LookupRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<CategoryModel>> getCategoriesByType(String type) async {
    final db = await _db;
    final rows = await db.query('categories', where: 'type = ? AND is_active = 1', whereArgs: [type], orderBy: 'name ASC');
    return rows.map(CategoryModel.fromMap).toList();
  }

  Future<List<AccountModel>> getActiveAccounts() async {
    final db = await _db;
    final rows = await db.query('accounts', where: 'is_active = 1', orderBy: 'name ASC');
    return rows.map(AccountModel.fromMap).toList();
  }
}
