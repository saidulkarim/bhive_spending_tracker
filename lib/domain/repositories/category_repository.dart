import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/local/app_database.dart';
import '../models/category_model.dart';

class CategoryRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<CategoryModel>> getByType(String type) async {
    final db = await _db;

    final rows = await db.query(
      'categories',
      where: 'type = ? AND is_active = 1',
      whereArgs: [type],
      orderBy: 'name ASC',
    );

    return rows.map(CategoryModel.fromMap).toList();
  }

  Future<int> insert({
    required String name,
    required String type,
    required IconData icon,
    required Color color,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();

    return db.insert(
      'categories',
      {
        'name': name.trim(),
        'type': type,
        'icon_code_point': icon.codePoint,
        'color_value': color.value,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(CategoryModel category) async {
    if (category.id == null) return 0;

    final db = await _db;

    return db.update(
      'categories',
      {
        'name': category.name.trim(),
        'type': category.type,
        'icon_code_point': category.iconCodePoint,
        'color_value': category.colorValue,
        'is_active': category.isActive ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deactivate(int id) async {
    final db = await _db;

    return db.update(
      'categories',
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
