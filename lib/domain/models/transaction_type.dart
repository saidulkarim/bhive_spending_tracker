enum TransactionType {
  income,
  expense;

  String get dbValue => name;

  static TransactionType fromDb(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionType.expense,
    );
  }
}
