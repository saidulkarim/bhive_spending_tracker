import 'package:sqflite/sqflite.dart';

import '../../data/local/app_database.dart';
import '../models/transaction_model.dart';
import '../models/transaction_type.dart';

class TransactionRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<int> insert(TransactionModel transaction) async {
    final db = await _db;

    return db.transaction<int>((txn) async {
      final int transactionId = await txn.insert(
        'transactions',
        transaction.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final double signedAmount = transaction.type == TransactionType.income
          ? transaction.amount
          : -transaction.amount;

      await txn.rawUpdate(
        '''
        UPDATE accounts
        SET current_balance = current_balance + ?,
            updated_at = ?
        WHERE id = ?
        ''',
        [signedAmount, DateTime.now().toIso8601String(), transaction.accountId],
      );

      return transactionId;
    });
  }

  Future<void> update(
    TransactionModel oldTransaction,
    TransactionModel newTransaction,
  ) async {
    if (oldTransaction.id == null) return;

    final db = await _db;

    await db.transaction<void>((txn) async {
      final double oldRollbackAmount =
          oldTransaction.type == TransactionType.income
          ? -oldTransaction.amount
          : oldTransaction.amount;

      await txn.rawUpdate(
        '''
        UPDATE accounts
        SET current_balance = current_balance + ?,
            updated_at = ?
        WHERE id = ?
        ''',
        [
          oldRollbackAmount,
          DateTime.now().toIso8601String(),
          oldTransaction.accountId,
        ],
      );

      final updateMap = newTransaction.toMap()
        ..remove('id')
        ..['updated_at'] = DateTime.now().toIso8601String();

      await txn.update(
        'transactions',
        updateMap,
        where: 'id = ?',
        whereArgs: [oldTransaction.id],
      );

      final double newSignedAmount =
          newTransaction.type == TransactionType.income
          ? newTransaction.amount
          : -newTransaction.amount;

      await txn.rawUpdate(
        '''
        UPDATE accounts
        SET current_balance = current_balance + ?,
            updated_at = ?
        WHERE id = ?
        ''',
        [
          newSignedAmount,
          DateTime.now().toIso8601String(),
          newTransaction.accountId,
        ],
      );
    });
  }

  Future<List<TransactionModel>> getAll({TransactionType? type}) async {
    final db = await _db;

    final String whereClause = type == null ? '' : 'WHERE t.type = ?';
    final List<Object?> args = type == null ? [] : [type.dbValue];

    final rows = await db.rawQuery('''
      SELECT
        t.*,
        c.name AS category_name,
        a.name AS account_name
      FROM transactions t
      LEFT JOIN categories c ON c.id = t.category_id
      LEFT JOIN accounts a ON a.id = t.account_id
      $whereClause
      ORDER BY t.transaction_date DESC, t.id DESC
      ''', args);

    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<void> delete(TransactionModel transaction) async {
    if (transaction.id == null) return;

    final db = await _db;

    await db.transaction<void>((txn) async {
      final double rollbackAmount = transaction.type == TransactionType.income
          ? -transaction.amount
          : transaction.amount;

      await txn.rawUpdate(
        '''
        UPDATE accounts
        SET current_balance = current_balance + ?,
            updated_at = ?
        WHERE id = ?
        ''',
        [
          rollbackAmount,
          DateTime.now().toIso8601String(),
          transaction.accountId,
        ],
      );

      await txn.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
    });
  }

  Future<double> getMonthlyTotal({
    required TransactionType type,
    required DateTime month,
  }) async {
    final db = await _db;

    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 1);

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE type = ?
      AND transaction_date >= ?
      AND transaction_date < ?
      ''',
      [type.dbValue, startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return (result.first['total'] as num).toDouble();
  }
}
