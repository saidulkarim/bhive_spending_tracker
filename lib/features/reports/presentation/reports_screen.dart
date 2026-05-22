// ignore_for_file: deprecated_member_use

import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/local/app_database.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.refreshTick});

  final int refreshTick;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool _loading = true;
  bool _showExpensePie = true;

  _MonthlyReportData _data = _MonthlyReportData.empty();

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  @override
  void didUpdateWidget(covariant ReportsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) {
      _loadReport();
    }
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);

    final db = await AppDatabase.instance.database;
    final data = await _ReportsQueryService(db).load(_selectedMonth);

    if (!mounted) return;

    setState(() {
      _data = data;
      _loading = false;
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );
    });

    _loadReport();
  }

  String _money(double amount) {
    final sign = amount < 0 ? '-' : '';
    final absolute = amount.abs();
    final parts = absolute.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final decimal = parts[1];

    if (whole.length <= 3) return '$sign৳$whole.$decimal';

    final lastThree = whole.substring(whole.length - 3);
    final remaining = whole.substring(0, whole.length - 3);
    final groups = <String>[];

    for (int i = remaining.length; i > 0; i -= 2) {
      final start = i - 2 < 0 ? 0 : i - 2;
      groups.insert(0, remaining.substring(start, i));
    }

    return '$sign৳${groups.join(',')},$lastThree.$decimal';
  }

  Future<void> _exportReport() async {
    final month = DateFormat('MMMM yyyy').format(_selectedMonth);

    final expenseTop = _data.expenseCategories.isEmpty
        ? 'No expense category'
        : '${_data.expenseCategories.first.name}: ${_money(_data.expenseCategories.first.total)}';

    final incomeTop = _data.incomeCategories.isEmpty
        ? 'No income category'
        : '${_data.incomeCategories.first.name}: ${_money(_data.incomeCategories.first.total)}';

    final text =
        '''
bHiVE Wallet Report
Month: $month

Financial Health: ${_data.healthStatus.title}
Income: ${_money(_data.income)}
Expense: ${_money(_data.expense)}
Saved / Net Balance: ${_money(_data.balance)}
Saving Rate: ${_data.savingRate.toStringAsFixed(1)}%
Daily Average Expense: ${_money(_data.dailyAverageExpense)}

Top Expense: $expenseTop
Top Income: $incomeTop

Previous Month Comparison:
Income Change: ${_money(_data.incomeChange)}
Expense Change: ${_money(_data.expenseChange)}

Total Account Balance: ${_money(_data.accountBalance)}
Total Transactions: ${_data.transactionCount}
''';

    await Share.share(text, subject: 'bHiVE Wallet Report - $month');
  }

  @override
  Widget build(BuildContext context) {
    final monthText = DateFormat('MMMM yyyy').format(_selectedMonth);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadReport,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              _MonthSelector(
                monthText: monthText,
                onPrevious: () => _changeMonth(-1),
                onNext: () => _changeMonth(1),
              ),

              const SizedBox(height: 16),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 90),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                _HealthScoreCard(data: _data, money: _money),

                const SizedBox(height: 16),

                _SavingRateCard(data: _data, money: _money),

                const SizedBox(height: 16),

                _TopAlertCard(data: _data, money: _money),

                const SizedBox(height: 16),

                _SixMonthTrendCard(items: _data.sixMonthTrend, money: _money),

                const SizedBox(height: 16),

                _PieToggleCard(
                  showExpense: _showExpensePie,
                  expenseItems: _data.expenseCategories,
                  incomeItems: _data.incomeCategories,
                  money: _money,
                  onToggle: (value) {
                    setState(() => _showExpensePie = value);
                  },
                ),

                const SizedBox(height: 16),

                _RankingCard(
                  title: 'Top 5 Expense Categories',
                  subtitle: 'Where your money goes most',
                  icon: Icons.trending_down_rounded,
                  items: _data.expenseCategories.take(5).toList(),
                  color: AppColors.danger,
                  money: _money,
                ),

                const SizedBox(height: 16),

                _RankingCard(
                  title: 'Top 5 Income Categories',
                  subtitle: 'Your major earning sources',
                  icon: Icons.trending_up_rounded,
                  items: _data.incomeCategories.take(5).toList(),
                  color: AppColors.success,
                  money: _money,
                ),

                const SizedBox(height: 16),

                _AccountBalanceCard(items: _data.accounts, money: _money),

                const SizedBox(height: 16),

                _MonthlyComparisonCard(data: _data, money: _money),

                const SizedBox(height: 16),

                _DailyAverageCard(data: _data, money: _money),

                const SizedBox(height: 16),

                _ExportReportCard(onExport: _exportReport),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportsQueryService {
  _ReportsQueryService(this.db);

  final Database db;

  Future<_MonthlyReportData> load(DateTime selectedMonth) async {
    final currentStart = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final currentEnd = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
    final previousStart = DateTime(
      selectedMonth.year,
      selectedMonth.month - 1,
      1,
    );
    final previousEnd = currentStart;

    final currentSummary = await _summary(currentStart, currentEnd);
    final previousSummary = await _summary(previousStart, previousEnd);

    final expenseCategories = await _categoryBreakdown(
      currentStart,
      currentEnd,
      'expense',
    );

    final incomeCategories = await _categoryBreakdown(
      currentStart,
      currentEnd,
      'income',
    );

    final trend = await _sixMonthTrend(selectedMonth);
    final accounts = await _accounts();

    final daysInMonth = DateUtils.getDaysInMonth(
      selectedMonth.year,
      selectedMonth.month,
    );

    final accountBalance = accounts.fold<double>(
      0,
      (sum, item) => sum + item.balance,
    );

    final income = currentSummary.income;
    final expense = currentSummary.expense;
    final balance = income - expense;

    final savingRate = income <= 0 ? 0.0 : (balance / income) * 100.0;
    final dailyAverageExpense = expense / daysInMonth;

    return _MonthlyReportData(
      income: income,
      expense: expense,
      balance: balance,
      accountBalance: accountBalance,
      transactionCount: currentSummary.transactionCount,
      previousIncome: previousSummary.income,
      previousExpense: previousSummary.expense,
      incomeChange: income - previousSummary.income,
      expenseChange: expense - previousSummary.expense,
      savingRate: savingRate,
      dailyAverageExpense: dailyAverageExpense,
      healthStatus: _HealthStatus.fromValues(
        income: income,
        expense: expense,
        savingRate: savingRate,
      ),
      expenseCategories: expenseCategories,
      incomeCategories: incomeCategories,
      sixMonthTrend: trend,
      accounts: accounts,
    );
  }

  Future<_SummaryRow> _summary(DateTime start, DateTime end) async {
    final rows = await db.rawQuery(
      '''
      SELECT type, COALESCE(SUM(amount), 0) AS total, COUNT(*) AS total_count
      FROM transactions
      WHERE transaction_date >= ?
      AND transaction_date < ?
      GROUP BY type
      ''',
      [start.toIso8601String(), end.toIso8601String()],
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

    return _SummaryRow(
      income: income,
      expense: expense,
      transactionCount: transactionCount,
    );
  }

  Future<List<_CategoryItem>> _categoryBreakdown(
    DateTime start,
    DateTime end,
    String type,
  ) async {
    final totalRows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE type = ?
      AND transaction_date >= ?
      AND transaction_date < ?
      ''',
      [type, start.toIso8601String(), end.toIso8601String()],
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
      [type, start.toIso8601String(), end.toIso8601String()],
    );

    return rows.map((row) {
      final total = (row['total'] as num?)?.toDouble() ?? 0;

      return _CategoryItem(
        name: row['category_name']?.toString() ?? 'Unknown',
        total: total,
        percent: grandTotal <= 0 ? 0 : (total / grandTotal) * 100,
      );
    }).toList();
  }

  Future<List<_MonthlyTrendItem>> _sixMonthTrend(DateTime selectedMonth) async {
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
      [startMonth.toIso8601String(), endMonth.toIso8601String()],
    );

    final Map<String, _MonthlyTrendItem> map = {};

    for (int i = 0; i < 6; i++) {
      final month = DateTime(startMonth.year, startMonth.month + i, 1);
      final key =
          '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';

      map[key] = _MonthlyTrendItem(month: month, income: 0, expense: 0);
    }

    for (final row in rows) {
      final key = row['month_key']?.toString();
      if (key == null || !map.containsKey(key)) continue;

      final existing = map[key]!;
      final type = row['type']?.toString();
      final total = (row['total'] as num?)?.toDouble() ?? 0;

      map[key] = _MonthlyTrendItem(
        month: existing.month,
        income: type == 'income' ? total : existing.income,
        expense: type == 'expense' ? total : existing.expense,
      );
    }

    return map.values.toList();
  }

  Future<List<_AccountItem>> _accounts() async {
    final rows = await db.query(
      'accounts',
      columns: ['name', 'current_balance'],
      where: 'is_active = 1',
      orderBy: 'current_balance DESC',
    );

    return rows.map((row) {
      return _AccountItem(
        name: row['name']?.toString() ?? 'Account',
        balance: (row['current_balance'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }
}

class _MonthlyReportData {
  const _MonthlyReportData({
    required this.income,
    required this.expense,
    required this.balance,
    required this.accountBalance,
    required this.transactionCount,
    required this.previousIncome,
    required this.previousExpense,
    required this.incomeChange,
    required this.expenseChange,
    required this.savingRate,
    required this.dailyAverageExpense,
    required this.healthStatus,
    required this.expenseCategories,
    required this.incomeCategories,
    required this.sixMonthTrend,
    required this.accounts,
  });

  final double income;
  final double expense;
  final double balance;
  final double accountBalance;
  final int transactionCount;
  final double previousIncome;
  final double previousExpense;
  final double incomeChange;
  final double expenseChange;
  final double savingRate;
  final double dailyAverageExpense;
  final _HealthStatus healthStatus;
  final List<_CategoryItem> expenseCategories;
  final List<_CategoryItem> incomeCategories;
  final List<_MonthlyTrendItem> sixMonthTrend;
  final List<_AccountItem> accounts;

  factory _MonthlyReportData.empty() {
    return const _MonthlyReportData(
      income: 0,
      expense: 0,
      balance: 0,
      accountBalance: 0,
      transactionCount: 0,
      previousIncome: 0,
      previousExpense: 0,
      incomeChange: 0,
      expenseChange: 0,
      savingRate: 0,
      dailyAverageExpense: 0,
      healthStatus: _HealthStatus.warning,
      expenseCategories: [],
      incomeCategories: [],
      sixMonthTrend: [],
      accounts: [],
    );
  }
}

class _SummaryRow {
  const _SummaryRow({
    required this.income,
    required this.expense,
    required this.transactionCount,
  });

  final double income;
  final double expense;
  final int transactionCount;
}

class _CategoryItem {
  const _CategoryItem({
    required this.name,
    required this.total,
    required this.percent,
  });

  final String name;
  final double total;
  final double percent;
}

class _MonthlyTrendItem {
  const _MonthlyTrendItem({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final double income;
  final double expense;
}

class _AccountItem {
  const _AccountItem({required this.name, required this.balance});

  final String name;
  final double balance;
}

enum _HealthStatus {
  good,
  warning,
  risk;

  String get title {
    switch (this) {
      case _HealthStatus.good:
        return 'Good';
      case _HealthStatus.warning:
        return 'Warning';
      case _HealthStatus.risk:
        return 'Risk';
    }
  }

  String get subtitle {
    switch (this) {
      case _HealthStatus.good:
        return 'Your monthly financial condition looks healthy.';
      case _HealthStatus.warning:
        return 'Your spending needs attention this month.';
      case _HealthStatus.risk:
        return 'Your expense is higher than income this month.';
    }
  }

  Color get color {
    switch (this) {
      case _HealthStatus.good:
        return AppColors.success;
      case _HealthStatus.warning:
        return AppColors.warning;
      case _HealthStatus.risk:
        return AppColors.danger;
    }
  }

  IconData get icon {
    switch (this) {
      case _HealthStatus.good:
        return Icons.verified_rounded;
      case _HealthStatus.warning:
        return Icons.warning_amber_rounded;
      case _HealthStatus.risk:
        return Icons.dangerous_rounded;
    }
  }

  static _HealthStatus fromValues({
    required double income,
    required double expense,
    required double savingRate,
  }) {
    if (income <= 0 && expense <= 0) return _HealthStatus.warning;
    if (expense > income) return _HealthStatus.risk;
    if (savingRate >= 20) return _HealthStatus.good;
    return _HealthStatus.warning;
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.monthText,
    required this.onPrevious,
    required this.onNext,
  });

  final String monthText;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              monthText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _HealthScoreCard extends StatelessWidget {
  const _HealthScoreCard({required this.data, required this.money});

  final _MonthlyReportData data;
  final String Function(double amount) money;

  @override
  Widget build(BuildContext context) {
    final status = data.healthStatus;

    return _ReportCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: status.color.withOpacity(0.18),
            child: Icon(status.icon, color: status.color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Health Score',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status.title,
                  style: TextStyle(
                    color: status.color,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status.subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavingRateCard extends StatelessWidget {
  const _SavingRateCard({required this.data, required this.money});

  final _MonthlyReportData data;
  final String Function(double amount) money;

  @override
  Widget build(BuildContext context) {
    final safeRate = data.savingRate.clamp(-100.0, 100.0);
    final progress = (safeRate / 100).clamp(0.0, 1.0);

    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            title: 'Saving Rate',
            subtitle: 'Income, expense and retained amount',
            icon: Icons.account_balance,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SmallMetric(
                  label: 'Income',
                  value: money(data.income),
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallMetric(
                  label: 'Expense',
                  value: money(data.expense),
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SmallMetric(
                  label: 'Saved / Net',
                  value: money(data.balance),
                  color: data.balance >= 0
                      ? AppColors.success
                      : AppColors.danger,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallMetric(
                  label: 'Saving Rate',
                  value: '${data.savingRate.toStringAsFixed(1)}%',
                  color: data.savingRate >= 0
                      ? AppColors.success
                      : AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                data.savingRate >= 0 ? AppColors.success : AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopAlertCard extends StatelessWidget {
  const _TopAlertCard({required this.data, required this.money});

  final _MonthlyReportData data;
  final String Function(double amount) money;

  @override
  Widget build(BuildContext context) {
    final hasExpense = data.expenseCategories.isNotEmpty;
    final item = hasExpense ? data.expenseCategories.first : null;

    return _ReportCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.danger.withOpacity(0.18),
            child: Icon(
              Icons.notification_important_rounded,
              color: AppColors.danger,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Expense Category Alert',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  hasExpense
                      ? 'Highest spending: ${item!.name} ${money(item.total)} (${item.percent.toStringAsFixed(1)}%)'
                      : 'No expense category recorded for this month.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SixMonthTrendCard extends StatelessWidget {
  const _SixMonthTrendCard({required this.items, required this.money});

  final List<_MonthlyTrendItem> items;
  final String Function(double amount) money;

  @override
  Widget build(BuildContext context) {
    final maxY = items.fold<double>(0, (maxValue, item) {
      final localMax = max(item.income, item.expense);
      return localMax > maxValue ? localMax : maxValue;
    });

    final hasData = maxY > 0;

    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            title: 'Expense vs Income Trend',
            subtitle: 'Last six months comparison',
            icon: Icons.bar_chart_rounded,
          ),
          const SizedBox(height: 18),
          if (!hasData)
            const _EmptyBox(
              icon: Icons.bar_chart_rounded,
              message: 'No trend data available yet.',
            )
          else
            SizedBox(
              height: 215,
              child: BarChart(
                BarChartData(
                  maxY: maxY * 1.25,
                  minY: 0,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        if (groupIndex < 0 || groupIndex >= items.length) {
                          return null;
                        }

                        final item = items[groupIndex];
                        final label = rodIndex == 0 ? 'Income' : 'Expense';

                        return BarTooltipItem(
                          '${DateFormat('MMM yyyy').format(item.month)}\n$label: ${money(rod.toY)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= items.length) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MMM').format(items[index].month),
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(items.length, (index) {
                    final item = items[index];

                    return BarChartGroupData(
                      x: index,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: item.income,
                          width: 9,
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        BarChartRodData(
                          toY: item.expense,
                          width: 9,
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              _LegendDot(color: AppColors.success, text: 'Income'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.danger, text: 'Expense'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PieToggleCard extends StatelessWidget {
  const _PieToggleCard({
    required this.showExpense,
    required this.expenseItems,
    required this.incomeItems,
    required this.money,
    required this.onToggle,
  });

  final bool showExpense;
  final List<_CategoryItem> expenseItems;
  final List<_CategoryItem> incomeItems;
  final String Function(double amount) money;
  final ValueChanged<bool> onToggle;

  static const List<Color> _colors = [
    Color(0xFFE6A23C),
    Color(0xFF2FA866),
    Color(0xFF5B8DEF),
    Color(0xFFE05B5B),
    Color(0xFFB26AE8),
    Color(0xFFA85B3A),
    Color(0xFF9D877D),
    Color(0xFF00A6A6),
  ];

  @override
  Widget build(BuildContext context) {
    final items = showExpense ? expenseItems : incomeItems;
    final total = items.fold<double>(0, (sum, item) => sum + item.total);
    final color = showExpense ? AppColors.danger : AppColors.success;

    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _CardHeader(
                  title: 'Category Pie Chart',
                  subtitle: 'Expense or income category share',
                  icon: Icons.pie_chart_rounded,
                ),
              ),
              Container(
                height: 36,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    _ToggleChip(
                      selected: showExpense,
                      label: 'Expense',
                      onTap: () => onToggle(true),
                    ),
                    _ToggleChip(
                      selected: !showExpense,
                      label: 'Income',
                      onTap: () => onToggle(false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty || total <= 0)
            _EmptyBox(
              icon: Icons.pie_chart_outline_rounded,
              message:
                  'No ${showExpense ? 'expense' : 'income'} data available.',
            )
          else ...[
            SizedBox(
              height: 205,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 45,
                  sections: List.generate(items.length, (index) {
                    final item = items[index];
                    final sectionColor = _colors[index % _colors.length];

                    return PieChartSectionData(
                      value: item.total,
                      color: sectionColor,
                      radius: 60,
                      title: '${item.percent.toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(items.length, (index) {
              final item = items[index];
              final sectionColor = _colors[index % _colors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: sectionColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      money(item.total),
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
    required this.color,
    required this.money,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<_CategoryItem> items;
  final Color color;
  final String Function(double amount) money;

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: title, subtitle: subtitle, icon: icon),
          const SizedBox(height: 16),
          if (items.isEmpty)
            _EmptyBox(icon: icon, message: 'No data found for this section.')
          else
            ...List.generate(items.length, (index) {
              final item = items[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: color.withOpacity(0.18),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              minHeight: 6,
                              value: (item.percent / 100).clamp(0.0, 1.0),
                              backgroundColor: AppColors.surface,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          money(item.total),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.percent.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _AccountBalanceCard extends StatelessWidget {
  const _AccountBalanceCard({required this.items, required this.money});

  final List<_AccountItem> items;
  final String Function(double amount) money;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (sum, item) => sum + item.balance);

    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            title: 'Account Balance Breakdown',
            subtitle: 'Cash, bank, mobile wallet and other accounts',
            icon: Icons.account_balance_wallet_rounded,
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const _EmptyBox(
              icon: Icons.account_balance_wallet_outlined,
              message: 'No active account found.',
            )
          else ...[
            Text(
              money(total),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 14),
            ...items.map((item) {
              final percent = total == 0
                  ? 0.0
                  : (item.balance / total).clamp(0.0, 1.0);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          money(item.balance),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: percent,
                        backgroundColor: AppColors.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.accentLight,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _MonthlyComparisonCard extends StatelessWidget {
  const _MonthlyComparisonCard({required this.data, required this.money});

  final _MonthlyReportData data;
  final String Function(double amount) money;

  @override
  Widget build(BuildContext context) {
    final incomePositive = data.incomeChange >= 0;
    final expensePositive = data.expenseChange <= 0;

    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            title: 'Monthly Comparison',
            subtitle: 'Current month compared with previous month',
            icon: Icons.compare_arrows_rounded,
          ),
          const SizedBox(height: 16),
          _ComparisonRow(
            title: 'Income Change',
            value: money(data.incomeChange),
            positive: incomePositive,
            note: incomePositive
                ? 'Income increased from last month.'
                : 'Income decreased from last month.',
          ),
          const SizedBox(height: 12),
          _ComparisonRow(
            title: 'Expense Change',
            value: money(data.expenseChange),
            positive: expensePositive,
            note: expensePositive
                ? 'Expense decreased from last month.'
                : 'Expense increased from last month.',
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.title,
    required this.value,
    required this.positive,
    required this.note,
  });

  final String title;
  final String value;
  final bool positive;
  final String note;

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            positive
                ? Icons.arrow_circle_up_rounded
                : Icons.arrow_circle_down_rounded,
            color: color,
            size: 27,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  note,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyAverageCard extends StatelessWidget {
  const _DailyAverageCard({required this.data, required this.money});

  final _MonthlyReportData data;
  final String Function(double amount) money;

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.warning.withOpacity(0.18),
            child: Icon(
              Icons.calendar_month_rounded,
              color: AppColors.warning,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Average Spending',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${money(data.dailyAverageExpense)} per day',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This helps you control daily spending habits.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportReportCard extends StatelessWidget {
  const _ExportReportCard({required this.onExport});

  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onExport,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 0.7),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.accent,
                child: Icon(
                  Icons.ios_share_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export / Share Report',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Share monthly summary with any supported app.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallMetric extends StatelessWidget {
  const _SmallMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textPrimary, size: 24),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 30),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
