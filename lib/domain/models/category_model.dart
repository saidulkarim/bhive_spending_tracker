class CategoryModel {
  const CategoryModel({
    this.id,
    required this.name,
    required this.type,
    required this.iconCodePoint,
    required this.colorValue,
    this.isActive = true,
  });

  final int? id;
  final String name;
  final String type;
  final int iconCodePoint;
  final int colorValue;
  final bool isActive;

  CategoryModel copyWith({
    int? id,
    String? name,
    String? type,
    int? iconCodePoint,
    int? colorValue,
    bool? isActive,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      isActive: isActive ?? this.isActive,
    );
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      iconCodePoint: map['icon_code_point'] as int,
      colorValue: map['color_value'] as int,
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }
}
