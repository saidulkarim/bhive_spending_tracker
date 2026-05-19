import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/account_model.dart';
import '../../../domain/repositories/account_repository.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final AccountRepository _repository = AccountRepository();

  List<AccountModel> _accounts = [];
  bool _loading = true;

  final List<Color> _colors = const [
    Color(0xFF2FA866),
    Color(0xFFE05B5B),
    Color(0xFF5B8DEF),
    Color(0xFFE6A23C),
    Color(0xFFA85B3A),
    Color(0xFFB26AE8),
    Color(0xFF8B4428),
    Color(0xFF9D877D),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final rows = await _repository.getAll();

    if (!mounted) return;

    setState(() {
      _accounts = rows;
      _loading = false;
    });
  }

  Future<void> _openSheet({AccountModel? model}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return _AccountFormSheet(
          repository: _repository,
          model: model,
          colors: _colors,
        );
      },
    );

    if (saved == true && mounted) {
      await _load();
    }
  }

  Future<void> _delete(AccountModel model) async {
    if (model.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Remove account?'),
          content: Text('“${model.name}” will be hidden from account list.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Remove'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await _repository.deactivate(model.id!);

    if (!mounted) return;

    await _load();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account removed.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _money(double amount) {
    return '৳${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final totalBalance = _accounts.fold<double>(
      0,
      (sum, item) => sum + item.currentBalance,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Accounts',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _openSheet(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Add',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: AppColors.textPrimary,
                            size: 28,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Balance',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _money(totalBalance),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    if (_accounts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(
                          child: Text(
                            'No accounts found.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ..._accounts.map((item) {
                        final color = Color(item.colorValue);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: color.withOpacity(0.18),
                                  child: Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: color,
                                  ),
                                ),

                                const SizedBox(width: 14),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Opening: ${_money(item.openingBalance)}',
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Current: ${_money(item.currentBalance)}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                IconButton(
                                  onPressed: () => _openSheet(model: item),
                                  icon: const Icon(
                                    Icons.edit_rounded,
                                    color: AppColors.textMuted,
                                  ),
                                ),

                                IconButton(
                                  onPressed: () => _delete(item),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }
}

class _AccountFormSheet extends StatefulWidget {
  const _AccountFormSheet({
    required this.repository,
    required this.model,
    required this.colors,
  });

  final AccountRepository repository;
  final AccountModel? model;
  final List<Color> colors;

  @override
  State<_AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<_AccountFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _openingBalanceController;
  late final TextEditingController _currentBalanceController;
  late Color _selectedColor;

  bool _saving = false;

  bool get _isEdit => widget.model != null;

  @override
  void initState() {
    super.initState();

    final model = widget.model;

    _nameController = TextEditingController(text: model?.name ?? '');
    _openingBalanceController = TextEditingController(
      text: model?.openingBalance.toStringAsFixed(2) ?? '0',
    );
    _currentBalanceController = TextEditingController(
      text: model?.currentBalance.toStringAsFixed(2) ?? '0',
    );

    _selectedColor = model == null ? AppColors.accent : Color(model.colorValue);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _openingBalanceController.dispose();
    _currentBalanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;

    final name = _nameController.text.trim();
    final openingBalance =
        double.tryParse(_openingBalanceController.text.trim()) ?? 0;

    final currentBalance =
        double.tryParse(_currentBalanceController.text.trim()) ??
        openingBalance;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account name is required.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    if (_isEdit) {
      await widget.repository.update(
        widget.model!.copyWith(
          name: name,
          openingBalance: openingBalance,
          currentBalance: currentBalance,
          colorValue: _selectedColor.value,
        ),
      );
    } else {
      await widget.repository.insert(
        name: name,
        openingBalance: openingBalance,
        color: _selectedColor,
      );
    }

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),

            const SizedBox(height: 22),

            Text(
              _isEdit ? 'Edit Account' : 'Add Account',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Account Name'),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _openingBalanceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Opening Balance',
                prefixText: '৳ ',
              ),
            ),

            if (_isEdit) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _currentBalanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Current Balance',
                  prefixText: '৳ ',
                ),
              ),
            ],

            const SizedBox(height: 20),

            const Text(
              'Color',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.colors.map((color) {
                final selected = _selectedColor.value == color.value;

                return InkWell(
                  onTap: () {
                    setState(() => _selectedColor = color);
                  },
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_isEdit ? Icons.save_rounded : Icons.add_rounded),
                label: Text(
                  _saving
                      ? 'Saving...'
                      : (_isEdit ? 'Update Account' : 'Save Account'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
