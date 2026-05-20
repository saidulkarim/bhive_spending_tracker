// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/account_model.dart';
import '../../../domain/models/category_model.dart';
import '../../../domain/models/transaction_model.dart';
import '../../../domain/models/transaction_type.dart';
import '../../../domain/repositories/lookup_repository.dart';
import '../../../domain/repositories/transaction_repository.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.initialType = TransactionType.expense,
    this.editTransaction,
  });

  final TransactionType initialType;
  final TransactionModel? editTransaction;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  final _lookupRepository = LookupRepository();
  final _transactionRepository = TransactionRepository();

  late TransactionType _type;
  late DateTime _selectedDate;

  List<CategoryModel> _categories = [];
  List<AccountModel> _accounts = [];

  CategoryModel? _selectedCategory;
  AccountModel? _selectedAccount;

  bool _loading = true;
  bool _saving = false;

  bool get _isEdit => widget.editTransaction != null;

  @override
  void initState() {
    super.initState();

    final edit = widget.editTransaction;

    _type = edit?.type ?? widget.initialType;
    _selectedDate = edit?.transactionDate ?? DateTime.now();

    if (edit != null) {
      _amountController.text = edit.amount.toStringAsFixed(2);
      _noteController.text = edit.note ?? '';
    }

    _loadLookups();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    setState(() => _loading = true);

    final categories = await _lookupRepository.getCategoriesByType(
      _type.dbValue,
    );
    final accounts = await _lookupRepository.getActiveAccounts();

    if (!mounted) return;

    final edit = widget.editTransaction;

    CategoryModel? selectedCategory;
    AccountModel? selectedAccount;

    if (edit != null) {
      for (final item in categories) {
        if (item.id == edit.categoryId) {
          selectedCategory = item;
          break;
        }
      }

      for (final item in accounts) {
        if (item.id == edit.accountId) {
          selectedAccount = item;
          break;
        }
      }
    }

    setState(() {
      _categories = categories;
      _accounts = accounts;
      _selectedCategory =
          selectedCategory ?? (categories.isNotEmpty ? categories.first : null);
      _selectedAccount =
          selectedAccount ?? (accounts.isNotEmpty ? accounts.first : null);
      _loading = false;
    });
  }

  Future<void> _changeType(TransactionType type) async {
    if (_type == type) return;

    setState(() {
      _type = type;
      _selectedCategory = null;
    });

    await _loadLookups();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null || _selectedAccount == null) {
      _showMessage('Please select category and account.');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final now = DateTime.now();

    setState(() => _saving = true);

    final transaction = TransactionModel(
      id: widget.editTransaction?.id,
      type: _type,
      amount: amount,
      categoryId: _selectedCategory!.id!,
      accountId: _selectedAccount!.id!,
      transactionDate: _selectedDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdAt: widget.editTransaction?.createdAt ?? now,
      updatedAt: now,
    );

    if (_isEdit) {
      await _transactionRepository.update(widget.editTransaction!, transaction);
    } else {
      await _transactionRepository.insert(transaction);
    }

    if (!mounted) return;

    setState(() => _saving = false);
    _showMessage(
      _isEdit
          ? 'Transaction updated successfully.'
          : 'Transaction saved successfully.',
    );
    Navigator.pop(context, true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd MMM yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 120),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _TypeButton(
                            text: 'Expense',
                            selected: _type == TransactionType.expense,
                            icon: Icons.trending_down_rounded,
                            onTap: () => _changeType(TransactionType.expense),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _TypeButton(
                            text: 'Income',
                            selected: _type == TransactionType.income,
                            icon: Icons.trending_up_rounded,
                            onTap: () => _changeType(TransactionType.income),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 22),

                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '৳ ',
                      ),
                      validator: (value) {
                        final amount = double.tryParse((value ?? '').trim());
                        if (amount == null || amount <= 0) {
                          return 'Enter a valid amount.';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16),

                    DropdownButtonFormField<CategoryModel>(
                      value: _selectedCategory,
                      dropdownColor: AppColors.surface,
                      decoration: InputDecoration(labelText: 'Category'),
                      items: _categories.map((category) {
                        return DropdownMenuItem<CategoryModel>(
                          value: category,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategory = value);
                      },
                      validator: (value) {
                        if (value == null) return 'Select category.';
                        return null;
                      },
                    ),

                    SizedBox(height: 16),

                    DropdownButtonFormField<AccountModel>(
                      value: _selectedAccount,
                      dropdownColor: AppColors.surface,
                      decoration: InputDecoration(labelText: 'Account'),
                      items: _accounts.map((account) {
                        return DropdownMenuItem<AccountModel>(
                          value: account,
                          child: Text(account.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedAccount = value);
                      },
                      validator: (value) {
                        if (value == null) return 'Select account.';
                        return null;
                      },
                    ),

                    SizedBox(height: 16),

                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(14),
                      child: InputDecorator(
                        decoration: InputDecoration(labelText: 'Date'),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month_rounded),
                            SizedBox(width: 12),
                            Text(
                              dateText,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Note',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_isEdit ? Icons.save_rounded : Icons.check_rounded),
              label: Text(
                _saving
                    ? 'Saving...'
                    : (_isEdit ? 'Update Transaction' : 'Save Transaction'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.text,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accent : AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: AppColors.textPrimary),
              SizedBox(height: 7),
              Text(
                text,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
