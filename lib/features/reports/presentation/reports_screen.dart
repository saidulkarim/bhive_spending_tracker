import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/repositories/report_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    required this.refreshTick,
  });

  final int refreshTick;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportRepository _repository = ReportRepository();

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  ReportSummary _summary = const ReportSummary(
    income: 0,
    expense: 0,
    balance: 0,
    accountBalance: 0,
    transactionCount: 0,
  );

  List<CategoryReportItem> _expenseItems = [];
  List<CategoryReportItem> _incomeItems = [];
  List<MonthlyTrendItem> _monthlyTrend = [];
  List<AccountBalanceItem> _accounts = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ReportsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final summary = await _repository.getMonthlySummary(_selectedMonth);
    final expenseItems = await _repository.getCategoryBreakdown(
      month: _selectedMonth,
      type: 'expense',
    );
    final incomeItems = await _repository.getCategoryBreakdown(
      month: _selectedMonth,
      type: 'income',
    );
    final trend = await _repository.getLastSixMonthsTrend(_selectedMonth);
    final accounts = await _repository.getAccountBalances();

    if (!mounted) return;

    setState(() {
      _summary = summary;
      _expenseItems = expenseItems;
      _incomeItems = incomeItems;
      _monthlyTrend = trend;
      _accounts = accounts;
      _loading = false;
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset);
    });

    _load();
  }

  String _money(double amount) {
    if (amount.abs() >= 100000) return '৳${amount.toStringAsFixed(0)}';
    return '৳${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final monthText = DateFormat('MMMM yyyy').format(_selectedMonth);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _load,
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
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                _InsightCard(
                  summary: _summary,
                  money: _money,
                ),

                const SizedBox(height: 16),

                _SixMonthBarChart(
                  items: _monthlyTrend,
                  money: _money,
                ),

                const SizedBox(height: 16),

                _AccountBalanceCard(
                  items: _accounts,
                  money: _money,
                ),

                const SizedBox(height: 16),

                _RankingCard(
                  title: 'Expense Ranking',
                  subtitle: 'Top expense categories for selected month',
                  icon: Icons.trending_down_rounded,
                  items: _expenseItems,
                  color: AppColors.danger,
                  money: _money,
                ),

                const SizedBox(height: 16),

                _RankingCard(
                  title: 'Income Ranking',
                  subtitle: 'Top income categories for selected month',
                  icon: Icons.trending_up_rounded,
                  items: _incomeItems,
                  color: AppColors.success,
                  money: _money,
                ),
              ],
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

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.summary,
    required this.money,
  });

  final ReportSummary summary;
  final String Function(double) money;

  @override
  Widget build(BuildContext context) {
    final savingRate = summary.income <= 0 ? 0 : (summary.balance / summary.income) * 100;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            title: 'Financial Insights',
            subtitle: 'Monthly performance snapshot',
            icon: Icons.auto_graph_rounded,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _InsightMetric(
                  label: 'Income',
                  value: money(summary.income),
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InsightMetric(
                  label: 'Expense',
                  value: money(summary.expense),
                  color: AppColors.danger,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _InsightMetric(
                  label: 'Net Balance',
                  value: money(summary.balance),
                  color: summary.balance >= 0 ? AppColors.success : AppColors.danger,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InsightMetric(
                  label: 'Saving Rate',
                  value: '${savingRate.toStringAsFixed(1)}%',
                  color: savingRate >= 0 ? AppColors.success : AppColors.danger,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: (savingRate / 100).clamp(0, 1),
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                savingRate >= 0 ? AppColors.success : AppColors.danger,
              ),
            ),
          ),

          const SizedBox(height: 9),

          Text(
            summary.income <= 0
                ? 'No income recorded for this month yet.'
                : 'You retained ${savingRate.toStringAsFixed(1)}% of your income this month.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightMetric extends StatelessWidget {
  const _InsightMetric({
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
            style: const TextStyle(
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

class _SixMonthBarChart extends StatelessWidget {
  const _SixMonthBarChart({
    required this.items,
    required this.money,
  });

  final List<MonthlyTrendItem> items;
  final String Function(double) money;

  @override
  Widget build(BuildContext context) {
    final maxY = items.fold<double>(
      0,
      (max, item) {
        final localMax = item.income > item.expense ? item.income : item.expense;
        return localMax > max ? localMax : max;
      },
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            title: 'Six-Month Trend',
            subtitle: 'Income and expense comparison',
            icon: Icons.bar_chart_rounded,
          ),

          const SizedBox(height: 18),

          if (maxY <= 0)
            const _EmptyBox(
              icon: Icons.bar_chart_rounded,
              message: 'No trend data available yet.',
            )
          else
            SizedBox(
              height: 210,
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
                        final item = items[groupIndex];
                        final label = rodIndex == 0 ? 'Income' : 'Expense';
                        return BarTooltipItem(
                          '${DateFormat('MMM yyyy').format(item.month)}\n$label: ${money(rod.toY)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                              style: const TextStyle(
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

class _AccountBalanceCard extends StatelessWidget {
  const _AccountBalanceCard({
    required this.items,
    required this.money,
  });

  final List<AccountBalanceItem> items;
  final String Function(double) money;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (sum, item) => sum + item.balance);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            title: 'Account Balance',
            subtitle: 'Current balance by account',
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
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 14),

            ...items.map((item) {
              final percent = total == 0 ? 0.0 : (item.balance / total).clamp(0.0, 1.0);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          money(item.balance),
                          style: const TextStyle(
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
  final List<CategoryReportItem> items;
  final Color color;
  final String Function(double) money;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: title,
            subtitle: subtitle,
            icon: icon,
          ),

          const SizedBox(height: 16),

          if (items.isEmpty)
            _EmptyBox(
              icon: icon,
              message: 'No data found for this section.',
            )
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
                            item.categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
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
                              value: (item.percent / 100).clamp(0, 1),
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
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.percent.toStringAsFixed(1)}%',
                          style: const TextStyle(
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
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
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
  const _EmptyBox({
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
