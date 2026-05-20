// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/transaction_model.dart';
import '../../../domain/models/transaction_type.dart';
import '../../../domain/repositories/transaction_repository.dart';
import 'add_transaction_screen.dart';

enum TransactionFilter { all, expense, income }

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({
    super.key,
    required this.refreshTick,
    required this.onChanged,
  });

  final int refreshTick;
  final VoidCallback onChanged;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionRepository _repository = TransactionRepository();

  TransactionFilter _filter = TransactionFilter.all;
  List<TransactionModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TransactionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) {
      _load();
    }
  }

  TransactionType? get _filterType {
    switch (_filter) {
      case TransactionFilter.expense:
        return TransactionType.expense;
      case TransactionFilter.income:
        return TransactionType.income;
      case TransactionFilter.all:
        return null;
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final items = await _repository.getAll(type: _filterType);

    if (!mounted) return;

    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _changeFilter(TransactionFilter filter) async {
    if (_filter == filter) return;

    setState(() => _filter = filter);
    await _load();
  }

  Future<void> _openAdd() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddTransactionScreen()),
    );

    if (result == true) {
      await _load();
      widget.onChanged();
    }
  }

  Future<void> _openEdit(TransactionModel item) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddTransactionScreen(editTransaction: item, initialType: item.type),
      ),
    );

    if (result == true) {
      await _load();
      widget.onChanged();
    }
  }

  Future<void> _delete(TransactionModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Delete transaction?'),
          content: Text(
            'This transaction will be removed and account balance will be adjusted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Yes, Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await _repository.delete(item);

    if (!mounted) return;

    await _load();
    widget.onChanged();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Transaction deleted.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _money(TransactionModel item) {
    final sign = item.type == TransactionType.income ? '+' : '-';
    return '$sign৳${item.amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Transactions',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 23,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: _TopAddButton(onPressed: _openAdd),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: 16),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 48,
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _FilterTab(
                      text: 'All',
                      selected: _filter == TransactionFilter.all,
                      onTap: () => _changeFilter(TransactionFilter.all),
                    ),
                    _FilterTab(
                      text: 'Expense',
                      selected: _filter == TransactionFilter.expense,
                      onTap: () => _changeFilter(TransactionFilter.expense),
                    ),
                    _FilterTab(
                      text: 'Income',
                      selected: _filter == TransactionFilter.income,
                      onTap: () => _changeFilter(TransactionFilter.income),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _loading
                    ? Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                    ? ListView(
                        padding: EdgeInsets.fromLTRB(20, 80, 20, 110),
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.textMuted,
                            size: 60,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No transactions found.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap Add to record your income or expense.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, 110),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return _TransactionTile(
                            item: item,
                            amountText: _money(item),
                            onEdit: () => _openEdit(item),
                            onDelete: () => _delete(item),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopAddButton extends StatelessWidget {
  const _TopAddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.add_rounded, size: 18),
      label: Text(
        'Add',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        minimumSize: Size(0, 38),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.item,
    required this.amountText,
    required this.onEdit,
    required this.onDelete,
  });

  final TransactionModel item;
  final String amountText;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isIncome = item.type == TransactionType.income;
    final date = DateFormat('dd MMM yyyy').format(item.transactionDate);
    final amountColor = isIncome ? AppColors.success : AppColors.danger;

    return Container(
      padding: EdgeInsets.fromLTRB(14, 13, 6, 13),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: isIncome
                ? AppColors.success.withOpacity(0.18)
                : AppColors.danger.withOpacity(0.18),
            child: Icon(
              isIncome
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: amountColor,
              size: 22,
            ),
          ),

          SizedBox(width: 12),

          Expanded(
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.categoryName ?? 'Category',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${item.accountName ?? 'Account'} • $date',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if ((item.note ?? '').trim().isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        item.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          SizedBox(width: 8),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountText,
                style: TextStyle(
                  color: amountColor,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onEdit,
                    icon: Icon(
                      Icons.edit_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.textMuted,
                      size: 21,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
