// ignore_for_file: deprecated_member_use

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_text.dart';
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

  DashboardSummary _summary = DashboardSummary(
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
  bool _showTrendPie = false;

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
    final topCategories = await _repository.getTopExpenseCategories(
      month: _month,
    );
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
    final sign = amount < 0 ? '-' : '';
    final absolute = amount.abs();
    final parts = absolute.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final decimal = parts[1];

    if (whole.length <= 3) {
      return '$sign৳$whole.$decimal';
    }

    final lastThree = whole.substring(whole.length - 3);
    final remaining = whole.substring(0, whole.length - 3);
    final groups = <String>[];

    for (int i = remaining.length; i > 0; i -= 2) {
      final start = i - 2 < 0 ? 0 : i - 2;
      groups.insert(0, remaining.substring(start, i));
    }

    return '$sign৳${groups.join(',')},$lastThree.$decimal';
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
              ? Center(child: CircularProgressIndicator())
              : ListView(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 110),
                  children: [
                    _MonthSelector(
                      monthText: monthText,
                      onPrevious: () => _changeMonth(-1),
                      onNext: () => _changeMonth(1),
                    ),

                    SizedBox(height: 16),

                    _HeroBalanceCard(
                      accountBalance: _money(_summary.accountBalance),
                      monthlyBalance: _money(_summary.balance),
                      transactionCount: _summary.transactionCount,
                    ),

                    SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            title: AppText.tr('Income', 'আয়'),
                            value: _money(_summary.income),
                            icon: Icons.trending_up_rounded,
                            color: AppColors.success,
                            onTap: () => _openAdd(TransactionType.income),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            title: AppText.tr('Expense', 'খরচ'),
                            value: _money(_summary.expense),
                            icon: Icons.trending_down_rounded,
                            color: AppColors.danger,
                            onTap: () => _openAdd(TransactionType.expense),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 18),

                    _RecentTransactionsCard(
                      items: _recentTransactions,
                      money: _money,
                    ),

                    SizedBox(height: 18),

                    _TrendChartCard(
                      items: _dailyTrend,
                      showPie: _showTrendPie,
                      onToggle: () {
                        setState(() => _showTrendPie = !_showTrendPie);
                      },
                    ),

                    SizedBox(height: 18),

                    _TopCategoriesCard(items: _topCategories, money: _money),
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
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: Icon(Icons.chevron_left_rounded),
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
            icon: Icon(Icons.chevron_right_rounded),
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
      padding: EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border, width: 0.7),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.12),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TakaBadge(size: 34, fontSize: 22),
                SizedBox(width: 12),
                Text(
                  AppText.tr('Total Account Balance', 'মোট অ্যাকাউন্ট ব্যালেন্স'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 10),

          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                accountBalance,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
            ),
          ),

          SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: AppText.tr('Monthly Net', 'মাসিক নিট'),
                  value: monthlyBalance,
                  child: _TakaBadge(size: 24, fontSize: 15),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _MiniMetric(
                  label: AppText.tr('Transactions', 'লেনদেন'),
                  value: transactionCount.toString(),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TakaBadge extends StatelessWidget {
  const _TakaBadge({required this.size, required this.fontSize});

  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.20),
        shape: BoxShape.circle,
      ),
      child: Text(
        '৳',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.child,
  });

  final String label;
  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          child,
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
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
          padding: EdgeInsets.all(15),
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
              SizedBox(height: 13),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
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

class _RecentTransactionsCard extends StatelessWidget {
  const _RecentTransactionsCard({required this.items, required this.money});

  final List<TransactionModel> items;
  final String Function(double amount) money;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            title: AppText.tr('Recent Transactions', 'সাম্প্রতিক লেনদেন'),
            icon: Icons.history_rounded,
          ),

          SizedBox(height: 10),

          if (items.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: _EmptyCardMessage(
                icon: Icons.receipt_long_rounded,
                message: AppText.tr('No transactions added yet.', 'এখনও কোনো লেনদেন যোগ করা হয়নি।'),
              ),
            )
          else
            ...items.map((item) {
              final isIncome = item.type == TransactionType.income;
              final color = isIncome ? AppColors.success : AppColors.danger;
              final sign = isIncome ? '+' : '-';
              final date = DateFormat('dd MMM').format(item.transactionDate);

              return Padding(
                padding: EdgeInsets.only(bottom: 10),
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

                    SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.categoryName ?? AppText.tr('Category', 'ক্যাটাগরি'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            '${item.accountName ?? AppText.tr('Account', 'অ্যাকাউন্ট')} • $date',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 8),

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

class _TrendChartCard extends StatelessWidget {
  const _TrendChartCard({
    required this.items,
    required this.showPie,
    required this.onToggle,
  });

  final List<DailyTrendItem> items;
  final bool showPie;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final hasData = items.any((e) => e.income > 0 || e.expense > 0);

    final incomeTotal = items.fold<double>(0, (sum, item) => sum + item.income);
    final expenseTotal = items.fold<double>(
      0,
      (sum, item) => sum + item.expense,
    );

    final incomeSpots = items
        .map((e) => FlSpot(e.day.toDouble(), e.income))
        .toList();

    final expenseSpots = items
        .map((e) => FlSpot(e.day.toDouble(), e.expense))
        .toList();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _CardTitle(
                  title: AppText.tr('Monthly Trend', 'মাসিক ট্রেন্ড'),
                  icon: Icons.show_chart_rounded,
                ),
              ),
              Container(
                height: 34,
                padding: EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _TrendToggleButton(
                      selected: !showPie,
                      icon: Icons.show_chart_rounded,
                      onTap: showPie ? onToggle : null,
                    ),
                    _TrendToggleButton(
                      selected: showPie,
                      icon: Icons.pie_chart_rounded,
                      onTap: showPie ? null : onToggle,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          if (!hasData)
            _EmptyCardMessage(
              icon: Icons.insights_rounded,
              message: AppText.tr('No trend data for this month.', 'এই মাসে কোনো ট্রেন্ড ডাটা নেই।'),
            )
          else if (showPie)
            SizedBox(
              height: 210,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 46,
                  sections: [
                    if (incomeTotal > 0)
                      PieChartSectionData(
                        value: incomeTotal,
                        color: AppColors.success,
                        radius: 62,
                        title: AppText.tr('Income', 'আয়'),
                        titleStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    if (expenseTotal > 0)
                      PieChartSectionData(
                        value: expenseTotal,
                        color: AppColors.danger,
                        radius: 62,
                        title: AppText.tr('Expense', 'খরচ'),
                        titleStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 190,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(enabled: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: incomeSpots,
                      isCurved: true,
                      barWidth: 3,
                      color: AppColors.success,
                      dotData: FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: expenseSpots,
                      isCurved: true,
                      barWidth: 3,
                      color: AppColors.danger,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),

          SizedBox(height: 12),

          Row(
            children: [
              _LegendDot(color: AppColors.success, text: AppText.tr('Income', 'আয়')),
              SizedBox(width: 16),
              _LegendDot(color: AppColors.danger, text: AppText.tr('Expense', 'খরচ')),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendToggleButton extends StatelessWidget {
  const _TrendToggleButton({
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 34,
          height: 28,
          child: Icon(
            icon,
            color: selected ? Colors.white : AppColors.textMuted,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _TopCategoriesCard extends StatelessWidget {
  const _TopCategoriesCard({required this.items, required this.money});

  final List<TopCategoryItem> items;
  final String Function(double amount) money;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            title: AppText.tr('Top Spending Categories', 'শীর্ষ খরচের ক্যাটাগরি'),
            icon: Icons.category_rounded,
          ),

          SizedBox(height: 16),

          if (items.isEmpty)
            _EmptyCardMessage(
              icon: Icons.category_outlined,
              message: AppText.tr('No expense category data yet.', 'এখনও খরচের ক্যাটাগরি ডাটা নেই।'),
            )
          else
            ...items.map((item) {
              final value = (item.percent / 100).clamp(0.0, 1.0);

              return Padding(
                padding: EdgeInsets.only(bottom: 13),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          money(item.total),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: value,
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
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textPrimary, size: 22),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
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
  const _EmptyCardMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 22, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 30),
          SizedBox(height: 10),
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
        SizedBox(width: 7),
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
