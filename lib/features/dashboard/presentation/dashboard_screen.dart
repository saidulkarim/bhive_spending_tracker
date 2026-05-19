import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/transaction_model.dart';
import '../../../domain/models/transaction_type.dart';
import '../../../domain/repositories/dashboard_repository.dart';
import '../../transactions/presentation/add_transaction_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.refreshTick,
    required this.onChanged,
  });

  final int refreshTick;
  final VoidCallback onChanged;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardRepository _repository = DashboardRepository();

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  DashboardSummary _summary = const DashboardSummary(
    income: 0,
    expense: 0,
    balance: 0,
    accountBalance: 0,
    transactionCount: 0,
  );

  List<TransactionModel> _recentTransactions = [];
  List<TopCategoryItem> _topCategories = [];
  List<DailyTrendItem> _dailyTrend = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshTick != widget.refreshTick) {
      _loadDashboard();
    }
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);

    final summary = await _repository.getMonthlySummary(_month);
    final recent = await _repository.getRecentTransactions(limit: 5);
    final topCategories = await _repository.getTopExpenseCategories(month: _month);
    final trend = await _repository.getDailyTrend(_month);

    if (!mounted) return;

    setState(() {
      _summary = summary;
      _recentTransactions = recent;
      _topCategories = topCategories;
      _dailyTrend = trend;
      _loading = false;
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
    });

    _loadDashboard();
  }

  Future<void> _openAdd(TransactionType type) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(initialType: type),
      ),
    );

    if (result == true) {
      await _loadDashboard();
      widget.onChanged();
    }
  }

  String _money(double amount) {
    if (amount.abs() >= 100000) {
      return '৳${amount.toStringAsFixed(0)}';
    }

    return '৳${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final monthText = DateFormat('MMMM yyyy').format(_month);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                  children: [
                    _MonthSelector(
                      monthText: monthText,
                      onPrevious: () => _changeMonth(-1),
                      onNext: () => _changeMonth(1),
                    ),

                    const SizedBox(height: 16),

                    _HeroBalanceCard(
                      accountBalance: _money(_summary.accountBalance),
                      monthlyBalance: _money(_summary.balance),
                      transactionCount: _summary.transactionCount,
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            title: 'Income',
                            value: _money(_summary.income),
                            icon: Icons.trending_up_rounded,
                            color: AppColors.success,
                            onTap: () => _openAdd(TransactionType.income),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            title: 'Expense',
                            value: _money(_summary.expense),
                            icon: Icons.trending_down_rounded,
                            color: AppColors.danger,
                            onTap: () => _openAdd(TransactionType.expense),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    _TrendChartCard(items: _dailyTrend),

                    const SizedBox(height: 18),

                    _TopCategoriesCard(
                      items: _topCategories,
                      money: _money,
                    ),

                    const SizedBox(height: 18),

                    _RecentTransactionsCard(
                      items: _recentTransactions,
                      money: _money,
                    ),
                  ],
                ),
        ),
      ),
    );
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
              style: const TextStyle(
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

class _HeroBalanceCard extends StatelessWidget {
  const _HeroBalanceCard({
    required this.accountBalance,
    required this.monthlyBalance,
    required this.transactionCount,
  });

  final String accountBalance;
  final String monthlyBalance;
  final int transactionCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border, width: 0.7),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.12),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Account Balance',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              accountBalance,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Monthly Net',
                  value: monthlyBalance,
                  icon: Icons.savings_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniMetric(
                  label: 'Transactions',
                  value: transactionCount.toString(),
                  icon: Icons.receipt_long_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                    ),
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

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border, width: 0.7),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.18),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 13),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendChartCard extends StatelessWidget {
  const _TrendChartCard({required this.items});

  final List<DailyTrendItem> items;

  @override
  Widget build(BuildContext context) {
    final hasData = items.any((e) => e.income > 0 || e.expense > 0);

    final incomeSpots = items
        .map((e) => FlSpot(e.day.toDouble(), e.income))
        .toList();

    final expenseSpots = items
        .map((e) => FlSpot(e.day.toDouble(), e.expense))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            title: 'Monthly Trend',
            icon: Icons.show_chart_rounded,
          ),

          const SizedBox(height: 16),

          if (!hasData)
            const _EmptyCardMessage(
              icon: Icons.insights_rounded,
              message: 'No trend data for this month.',
            )
          else
            SizedBox(
              height: 190,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(enabled: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: incomeSpots,
                      isCurved: true,
                      barWidth: 3,
                      color: AppColors.success,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: expenseSpots,
                      isCurved: true,
                      barWidth: 3,
                      color: AppColors.danger,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          const Row(
            children: [
              _LegendDot(color: AppColors.success, text: 'Income'),
              SizedBox(width: 16),
              _LegendDot(color: AppColors.danger, text: 'Expense'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopCategoriesCard extends StatelessWidget {
  const _TopCategoriesCard({
    required this.items,
    required this.money,
  });

  final List<TopCategoryItem> items;
  final String Function(double amount) money;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            title: 'Top Spending Categories',
            icon: Icons.category_rounded,
          ),

          const SizedBox(height: 16),

          if (items.isEmpty)
            const _EmptyCardMessage(
              icon: Icons.category_outlined,
              message: 'No expense category data yet.',
            )
          else
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          money(item.total),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: (item.percent / 100).clamp(0, 1),
                        backgroundColor: AppColors.surface,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accentLight,
                        ),
                      ),
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

class _RecentTransactionsCard extends StatelessWidget {
  const _RecentTransactionsCard({
    required this.items,
    required this.money,
  });

  final List<TransactionModel> items;
  final String Function(double amount) money;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            title: 'Recent Transactions',
            icon: Icons.history_rounded,
          ),

          const SizedBox(height: 10),

          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: _EmptyCardMessage(
                icon: Icons.receipt_long_rounded,
                message: 'No transactions added yet.',
              ),
            )
          else
            ...items.map((item) {
              final isIncome = item.type == TransactionType.income;
              final color = isIncome ? AppColors.success : AppColors.danger;
              final sign = isIncome ? '+' : '-';
              final date = DateFormat('dd MMM').format(item.transactionDate);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: color.withOpacity(0.18),
                      child: Icon(
                        isIncome
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: color,
                        size: 21,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.categoryName ?? 'Category',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${item.accountName ?? 'Account'} • $date',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    Text(
                      '$sign${money(item.amount)}',
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
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

class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textPrimary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyCardMessage extends StatelessWidget {
  const _EmptyCardMessage({
    required this.icon,
    required this.message,
  });

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
            style: const TextStyle(
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
  const _LegendDot({
    required this.color,
    required this.text,
  });

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
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
