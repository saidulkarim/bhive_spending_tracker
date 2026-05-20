// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/category_model.dart';
import '../../../domain/models/transaction_type.dart';
import '../../../domain/repositories/category_repository.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoryRepository _repository = CategoryRepository();

  TransactionType _selectedType = TransactionType.expense;
  List<CategoryModel> _categories = [];
  bool _loading = true;

  static final List<IconData> _availableIcons = [
    Icons.restaurant_rounded,
    Icons.directions_bus_rounded,
    Icons.shopping_bag_rounded,
    Icons.receipt_long_rounded,
    Icons.local_hospital_rounded,
    Icons.school_rounded,
    Icons.groups_rounded,
    Icons.home_rounded,
    Icons.flight_takeoff_rounded,
    Icons.phone_android_rounded,
    Icons.electrical_services_rounded,
    Icons.water_drop_rounded,
    Icons.local_grocery_store_rounded,
    Icons.coffee_rounded,
    Icons.card_giftcard_rounded,
    Icons.business_center_rounded,
    Icons.laptop_mac_rounded,
    Icons.trending_up_rounded,
    Icons.category_rounded,
  ];

  static final List<Color> _availableColors = [
    Color(0xFF2FA866),
    Color(0xFFE05B5B),
    Color(0xFFE6A23C),
    Color(0xFF5B8DEF),
    Color(0xFFB26AE8),
    Color(0xFFA85B3A),
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

    final rows = await _repository.getByType(_selectedType.dbValue);

    if (!mounted) return;

    setState(() {
      _categories = rows;
      _loading = false;
    });
  }

  Future<void> _changeType(TransactionType type) async {
    if (_selectedType == type) return;

    setState(() => _selectedType = type);
    await _load();
  }

  Future<void> _openCategorySheet({CategoryModel? category}) async {
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return _CategoryFormSheet(
          repository: _repository,
          category: category,
          selectedType: _selectedType,
          availableIcons: _availableIcons,
          availableColors: _availableColors,
        );
      },
    );

    if (saved == true && mounted) {
      await _load();
    }
  }

  Future<void> _deactivate(CategoryModel category) async {
    if (category.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Remove category?'),
          content: Text(
            '“${category.name}” will be hidden from future transactions.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('Yes, Remove'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await _repository.deactivate(category.id!);

    if (!mounted) return;

    await _load();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Category removed.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _selectedType == TransactionType.expense;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Categories',
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
            child: ElevatedButton.icon(
              onPressed: () => _openCategorySheet(),
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
                    _TypeTab(
                      text: 'Expense',
                      selected: isExpense,
                      onTap: () => _changeType(TransactionType.expense),
                    ),
                    _TypeTab(
                      text: 'Income',
                      selected: !isExpense,
                      onTap: () => _changeType(TransactionType.income),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator())
                  : _categories.isEmpty
                  ? Center(
                      child: Text(
                        'No categories found.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, 110),
                        itemCount: _categories.length,
                        separatorBuilder: (_, _) => SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final category = _categories[index];

                          return _CategoryTile(
                            category: category,
                            onEdit: () =>
                                _openCategorySheet(category: category),
                            onDelete: () => _deactivate(category),
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

class _CategoryFormSheet extends StatefulWidget {
  const _CategoryFormSheet({
    required this.repository,
    required this.category,
    required this.selectedType,
    required this.availableIcons,
    required this.availableColors,
  });

  final CategoryRepository repository;
  final CategoryModel? category;
  final TransactionType selectedType;
  final List<IconData> availableIcons;
  final List<Color> availableColors;

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  late final TextEditingController _nameController;
  late IconData _selectedIcon;
  late Color _selectedColor;

  bool _saving = false;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();

    final category = widget.category;

    _nameController = TextEditingController(text: category?.name ?? '');

    _selectedIcon = category == null
        ? (widget.selectedType == TransactionType.income
              ? Icons.trending_up_rounded
              : Icons.category_rounded)
        : IconData(category.iconCodePoint, fontFamily: 'MaterialIcons');

    _selectedColor = category == null
        ? AppColors.accent
        : Color(category.colorValue);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;

    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category name is required.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    if (_isEdit) {
      await widget.repository.update(
        widget.category!.copyWith(
          name: name,
          iconCodePoint: _selectedIcon.codePoint,
          colorValue: _selectedColor.value,
        ),
      );
    } else {
      await widget.repository.insert(
        name: name,
        type: widget.selectedType.dbValue,
        icon: _selectedIcon,
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
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),

            SizedBox(height: 20),

            Text(
              _isEdit ? 'Edit Category' : 'Add Category',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),

            SizedBox(height: 18),

            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.done,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(labelText: 'Category Name'),
            ),

            SizedBox(height: 22),

            Text(
              'Icon',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),

            SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.availableIcons.map((icon) {
                final selected = icon.codePoint == _selectedIcon.codePoint;

                return InkWell(
                  onTap: () {
                    setState(() => _selectedIcon = icon);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.accent : AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? AppColors.accentLight
                            : AppColors.border,
                      ),
                    ),
                    child: Icon(icon, color: AppColors.textPrimary, size: 23),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 22),

            Text(
              'Color',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),

            SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.availableColors.map((color) {
                final selected = color.value == _selectedColor.value;

                return InkWell(
                  onTap: () {
                    setState(() => _selectedColor = color);
                  },
                  customBorder: CircleBorder(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.textPrimary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 26),

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
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_isEdit ? Icons.save_rounded : Icons.add_rounded),
                label: Text(
                  _saving
                      ? 'Saving...'
                      : (_isEdit ? 'Update Category' : 'Save Category'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  const _TypeTab({
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final icon = IconData(category.iconCodePoint, fontFamily: 'MaterialIcons');

    final color = Color(category.colorValue);

    return Container(
      padding: EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.20),
            child: Icon(icon, color: color, size: 23),
          ),

          SizedBox(width: 14),

          Expanded(
            child: Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
            icon: Icon(
              Icons.edit_rounded,
              color: AppColors.textMuted,
              size: 21,
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
    );
  }
}
