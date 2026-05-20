import 'package:sqflite/sqflite.dart';

import '../../data/local/app_database.dart';
import '../models/transaction_model.dart';

class DashboardSummary {
  DashboardSummary({
    required this.income,
    required this.expense,
    required this.balance,
    required this.accountBalance,
    required this.transactionCount,
  });

  final double income;
  final double expense;
  final double balance;
  final double accountBalance;
  final int transactionCount;
}

class TopCategoryItem {
  TopCategoryItem({
    required this.name,
    required this.total,
    required this.percent,
  });

  final String name;
  final double total;
  final double percent;
}

class DailyTrendItem {
  DailyTrendItem({
    required this.day,
    required this.income,
    required this.expense,
  });

  final int day;
  final double income;
  final double expense;
}

class DashboardRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<DashboardSummary> getMonthlySummary(DateTime month) async {
    final db = await _db;

    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 1);

    final rows = await db.rawQuery(
      '''
      SELECT type, COALESCE(SUM(amount), 0) AS total, COUNT(*) AS total_count
      FROM transactions
      WHERE transaction_date >= ?
      AND transaction_date < ?
      GROUP BY type
      ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    double income = 0;
    double expense = 0;
    int count = 0;

    for (final row in rows) {
      final type = row['type']?.toString();
      final total = (row['total'] as num?)?.toDouble() ?? 0;
      final totalCount = (row['total_count'] as num?)?.toInt() ?? 0;

      count += totalCount;

      if (type == 'income') income = total;
      if (type == 'expense') expense = total;
    }

    final accountRows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(current_balance), 0) AS total
      FROM accounts
      WHERE is_active = 1
      ''',
    );

    final accountBalance =
        (accountRows.first['total'] as num?)?.toDouble() ?? 0;

    return DashboardSummary(
      income: income,
      expense: expense,
      balance: income - expense,
      accountBalance: accountBalance,
      transactionCount: count,
    );
  }

  Future<List<TransactionModel>> getRecentTransactions({int limit = 5}) async {
    final db = await _db;

    final rows = await db.rawQuery(
      '''
      SELECT
        t.*,
        c.name AS category_name,
        a.name AS account_name
      FROM transactions t
      LEFT JOIN categories c ON c.id = t.category_id
      LEFT JOIN accounts a ON a.id = t.account_id
      ORDER BY t.transaction_date DESC, t.id DESC
      LIMIT ?
      ''',
      [limit],
    );

    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<List<TopCategoryItem>> getTopExpenseCategories({
    required DateTime month,
    int limit = 5,
  }) async {
    final db = await _db;

    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 1);

    final totalRows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE type = 'expense'
      AND transaction_date >= ?
      AND transaction_date < ?
      ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    final totalExpense = (totalRows.first['total'] as num?)?.toDouble() ?? 0;

    if (totalExpense <= 0) return [];

    final rows = await db.rawQuery(
      '''
      SELECT c.name AS category_name, COALESCE(SUM(t.amount), 0) AS total
      FROM transactions t
      LEFT JOIN categories c ON c.id = t.category_id
      WHERE t.type = 'expense'
      AND t.transaction_date >= ?
      AND t.transaction_date < ?
      GROUP BY c.name
      ORDER BY total DESC
      LIMIT ?
      ''',
      [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
        limit,
      ],
    );

    return rows.map((row) {
      final total = (row['total'] as num?)?.toDouble() ?? 0;

      return TopCategoryItem(
        name: row['category_name']?.toString() ?? 'Unknown',
        total: total,
        percent: totalExpense == 0 ? 0 : (total / totalExpense) * 100,
      );
    }).toList();
  }

  Future<List<DailyTrendItem>> getDailyTrend(DateTime month) async {
    final db = await _db;

    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 1);

    final rows = await db.rawQuery(
      '''
      SELECT
        CAST(strftime('%d', transaction_date) AS INTEGER) AS day,
        type,
        COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE transaction_date >= ?
      AND transaction_date < ?
      GROUP BY day, type
      ORDER BY day ASC
      ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    final Map<int, DailyTrendItem> map = {};

    for (final row in rows) {
      final day = (row['day'] as num?)?.toInt() ?? 1;
      final type = row['type']?.toString();
      final total = (row['total'] as num?)?.toDouble() ?? 0;

      final current = map[day] ??
          DailyTrendItem(
            day: day,
            income: 0,
            expense: 0,
          );

      map[day] = DailyTrendItem(
        day: day,
        income: type == 'income' ? total : current.income,
        expense: type == 'expense' ? total : current.expense,
      );
    }

    return map.values.toList()..sort((a, b) => a.day.compareTo(b.day));
  }
}
