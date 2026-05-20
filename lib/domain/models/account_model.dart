class AccountModel {
  AccountModel({
    this.id,
    required this.name,
    required this.openingBalance,
    required this.currentBalance,
    required this.iconCodePoint,
    required this.colorValue,
    this.isActive = true,
  });

  final int? id;
  final String name;
  final double openingBalance;
  final double currentBalance;
  final int iconCodePoint;
  final int colorValue;
  final bool isActive;

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      openingBalance: (map['opening_balance'] as num?)?.toDouble() ?? 0,
      currentBalance: (map['current_balance'] as num?)?.toDouble() ?? 0,
      iconCodePoint: (map['icon_code_point'] as int?) ?? 0xe850,
      colorValue: (map['color_value'] as int?) ?? 0xFF8B4428,
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }

  AccountModel copyWith({
    int? id,
    String? name,
    double? openingBalance,
    double? currentBalance,
    int? iconCodePoint,
    int? colorValue,
    bool? isActive,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      isActive: isActive ?? this.isActive,
    );
  }
}
