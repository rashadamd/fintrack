// lib/models/transaction.dart

// Equivalent to TransactionType enum in TypeScript
enum TransactionType {
  income,
  expense,
}

class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final DateTime date;
  final String description;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.description,
  });
}