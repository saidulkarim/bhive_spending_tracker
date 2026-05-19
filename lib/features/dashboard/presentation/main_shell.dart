import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/transaction_type.dart';
import '../../about/presentation/about_screen.dart';
import '../../accounts/presentation/accounts_screen.dart';
import '../../backup/presentation/backup_screen.dart';
import '../../categories/presentation/categories_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../transactions/presentation/add_transaction_screen.dart';
import '../../transactions/presentation/transactions_screen.dart';
import 'dashboard_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _refreshTick = 0;

  void _refreshAll() => setState(() => _refreshTick++);

  void _goBottomTab(int index) {
    Navigator.pop(context);
    setState(() => _index = index);
  }

  void _openDrawerPage(Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page))
        .then((_) => _refreshAll());
  }

  bool get _showFloatingAdd {
    return _index == 0 || _index == 1 || _index == 3;
  }

  String get _title {
    switch (_index) {
      case 0:
        return 'bHiVE Wallet';
      case 1:
        return 'Transactions';
      case 2:
        return 'Categories';
      case 3:
        return 'Reports';
      default:
        return 'bHiVE Wallet';
    }
  }

  Future<void> _openAddTransaction(TransactionType type) async {
    Navigator.pop(context);

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(initialType: type),
      ),
    );

    if (result == true && mounted) {
      _refreshAll();
    }
  }

  void _showQuickAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  'Quick Transaction',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Choose what you want to record now.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: _QuickAddOption(
                        title: 'Add Expense',
                        subtitle: 'Spending record',
                        icon: Icons.trending_down_rounded,
                        color: AppColors.danger,
                        onTap: () => _openAddTransaction(
                          TransactionType.expense,
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: _QuickAddOption(
                        title: 'Add Income',
                        subtitle: 'Earning record',
                        icon: Icons.trending_up_rounded,
                        color: AppColors.success,
                        onTap: () => _openAddTransaction(
                          TransactionType.income,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(refreshTick: _refreshTick, onChanged: _refreshAll),
      TransactionsScreen(refreshTick: _refreshTick, onChanged: _refreshAll),
      const CategoriesScreen(),
      ReportsScreen(refreshTick: _refreshTick),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Drawer(
        backgroundColor: AppColors.background,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.accent,
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'bHiVE Wallet',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Offline spending tracker',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: [
                    _DrawerItem(
                      icon: Icons.dashboard_rounded,
                      title: 'Dashboard',
                      selected: _index == 0,
                      onTap: () => _goBottomTab(0),
                    ),
                    _DrawerItem(
                      icon: Icons.receipt_long_rounded,
                      title: 'Transactions',
                      selected: _index == 1,
                      onTap: () => _goBottomTab(1),
                    ),
                    _DrawerItem(
                      icon: Icons.category_rounded,
                      title: 'Categories',
                      selected: _index == 2,
                      onTap: () => _goBottomTab(2),
                    ),
                    _DrawerItem(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Accounts',
                      onTap: () => _openDrawerPage(const AccountsScreen()),
                    ),
                    _DrawerItem(
                      icon: Icons.pie_chart_rounded,
                      title: 'Reports',
                      selected: _index == 3,
                      onTap: () => _goBottomTab(3),
                    ),
                    _DrawerItem(
                      icon: Icons.backup_rounded,
                      title: 'Backup / Restore',
                      onTap: () => _openDrawerPage(const BackupScreen()),
                    ),
                    const Divider(color: AppColors.border, height: 24),
                    _DrawerItem(
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      onTap: () => _openDrawerPage(const SettingsScreen()),
                    ),
                    _DrawerItem(
                      icon: Icons.info_outline_rounded,
                      title: 'About',
                      onTap: () => _openDrawerPage(const AboutScreen()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          _title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: IndexedStack(index: _index, children: screens),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _showFloatingAdd
          ? Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _PremiumFloatingAddButton(
                onTap: _showQuickAddSheet,
              ),
            )
          : null,

      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 76,
          decoration: const BoxDecoration(
            color: AppColors.bottomBar,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 0.6),
            ),
          ),
          child: Row(
            children: [
              _NavItem(
                selected: _index == 0,
                icon: Icons.dashboard_rounded,
                label: 'Home',
                onTap: () => setState(() => _index = 0),
              ),
              _NavItem(
                selected: _index == 1,
                icon: Icons.receipt_long_rounded,
                label: 'List',
                onTap: () => setState(() => _index = 1),
              ),

              const SizedBox(width: 72),

              _NavItem(
                selected: _index == 2,
                icon: Icons.category_rounded,
                label: 'Category',
                onTap: () => setState(() => _index = 2),
              ),
              _NavItem(
                selected: _index == 3,
                icon: Icons.pie_chart_rounded,
                label: 'Reports',
                onTap: () => setState(() => _index = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumFloatingAddButton extends StatelessWidget {
  const _PremiumFloatingAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      elevation: 12,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accentLight,
                AppColors.accent,
                AppColors.accentDark,
              ],
            ),
            border: Border.all(
              color: AppColors.textPrimary,
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.35),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }
}

class _QuickAddOption extends StatelessWidget {
  const _QuickAddOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 18, 15, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.border,
              width: 0.7,
            ),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.18),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    this.selected = false,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accentDark : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    selected ? AppColors.textPrimary : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight:
                        selected ? FontWeight.w800 : FontWeight.w600,
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textPrimary : AppColors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 7, 4, 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: selected ? AppColors.accentDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: color,
                    fontSize: 11.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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
