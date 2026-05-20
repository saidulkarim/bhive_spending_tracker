import 'transaction_type.dart';

class TransactionModel {
  TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    required this.transactionDate,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
    this.accountName,
  });

  final int? id;
  final TransactionType type;
  final double amount;
  final int categoryId;
  final int accountId;
  final DateTime transactionDate;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String? categoryName;
  final String? accountName;

  TransactionModel copyWith({
    int? id,
    TransactionType? type,
    double? amount,
    int? categoryId,
    int? accountId,
    DateTime? transactionDate,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
    String? accountName,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      transactionDate: transactionDate ?? this.transactionDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: categoryName ?? this.categoryName,
      accountName: accountName ?? this.accountName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.dbValue,
      'amount': amount,
      'category_id': categoryId,
      'account_id': accountId,
      'transaction_date': transactionDate.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      type: TransactionType.fromDb(map['type'] as String),
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as int,
      accountId: map['account_id'] as int,
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      categoryName: map['category_name'] as String?,
      accountName: map['account_name'] as String?,
    );
  }
}
