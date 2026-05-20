import 'package:sqflite/sqflite.dart';

import '../../data/local/app_database.dart';

class ReportSummary {
  ReportSummary({
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

class CategoryReportItem {
  CategoryReportItem({
    required this.categoryName,
    required this.total,
    required this.percent,
  });

  final String categoryName;
  final double total;
  final double percent;
}

class MonthlyTrendItem {
  MonthlyTrendItem({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final double income;
  final double expense;
}

class AccountBalanceItem {
  AccountBalanceItem({
    required this.name,
    required this.balance,
  });

  final String name;
  final double balance;
}

class ReportRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<ReportSummary> getMonthlySummary(DateTime month) async {
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
      [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
    );

    double income = 0;
    double expense = 0;
    int transactionCount = 0;

    for (final row in rows) {
      final type = row['type']?.toString();
      final total = (row['total'] as num?)?.toDouble() ?? 0;
      final count = (row['total_count'] as num?)?.toInt() ?? 0;

      transactionCount += count;

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

    return ReportSummary(
      income: income,
      expense: expense,
      balance: income - expense,
      accountBalance: accountBalance,
      transactionCount: transactionCount,
    );
  }

  Future<List<CategoryReportItem>> getCategoryBreakdown({
    required DateTime month,
    required String type,
  }) async {
    final db = await _db;

    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 1);

    final totalRows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE type = ?
      AND transaction_date >= ?
      AND transaction_date < ?
      ''',
      [
        type,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
    );

    final grandTotal = (totalRows.first['total'] as num?)?.toDouble() ?? 0;

    if (grandTotal <= 0) return [];

    final rows = await db.rawQuery(
      '''
      SELECT c.name AS category_name, COALESCE(SUM(t.amount), 0) AS total
      FROM transactions t
      LEFT JOIN categories c ON c.id = t.category_id
      WHERE t.type = ?
      AND t.transaction_date >= ?
      AND t.transaction_date < ?
      GROUP BY c.name
      ORDER BY total DESC
      ''',
      [
        type,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
    );

    return rows.map((row) {
      final total = (row['total'] as num?)?.toDouble() ?? 0;

      return CategoryReportItem(
        categoryName: row['category_name']?.toString() ?? 'Unknown',
        total: total,
        percent: grandTotal == 0 ? 0 : (total / grandTotal) * 100,
      );
    }).toList();
  }

  Future<List<MonthlyTrendItem>> getLastSixMonthsTrend(DateTime selectedMonth) async {
    final db = await _db;

    final startMonth = DateTime(selectedMonth.year, selectedMonth.month - 5, 1);
    final endMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);

    final rows = await db.rawQuery(
      '''
      SELECT
        strftime('%Y-%m', transaction_date) AS month_key,
        type,
        COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE transaction_date >= ?
      AND transaction_date < ?
      GROUP BY month_key, type
      ORDER BY month_key ASC
      ''',
      [
        startMonth.toIso8601String(),
        endMonth.toIso8601String(),
      ],
    );

    final Map<String, MonthlyTrendItem> map = {};

    for (int i = 0; i < 6; i++) {
      final month = DateTime(startMonth.year, startMonth.month + i, 1);
      final key = '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
      map[key] = MonthlyTrendItem(month: month, income: 0, expense: 0);
    }

    for (final row in rows) {
      final key = row['month_key']?.toString();
      if (key == null || !map.containsKey(key)) continue;

      final type = row['type']?.toString();
      final total = (row['total'] as num?)?.toDouble() ?? 0;
      final existing = map[key]!;

      map[key] = MonthlyTrendItem(
        month: existing.month,
        income: type == 'income' ? total : existing.income,
        expense: type == 'expense' ? total : existing.expense,
      );
    }

    return map.values.toList();
  }

  Future<List<AccountBalanceItem>> getAccountBalances() async {
    final db = await _db;

    final rows = await db.query(
      'accounts',
      columns: ['name', 'current_balance'],
      where: 'is_active = 1',
      orderBy: 'current_balance DESC',
    );

    return rows.map((row) {
      return AccountBalanceItem(
        name: row['name']?.toString() ?? 'Account',
        balance: (row['current_balance'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }
}
