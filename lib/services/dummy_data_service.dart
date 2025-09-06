import 'package:fintrack/models/budget.dart';
import 'package:fintrack/models/transaction.dart';

class DummyDataService {
  List<Transaction> get transactions => [
    Transaction(
      id: '1',
      type: TransactionType.income,
      amount: 3000,
      categoryId: 'salary',
      date: DateTime.now(),
      description: 'Monthly Salary',
    ),
    Transaction(
      id: '2',
      type: TransactionType.expense,
      amount: 50,
      categoryId: 'food',
      date: DateTime.now().subtract(const Duration(days: 1)),
      description: 'Lunch with colleagues',
    ),
    Transaction(
      id: '3',
      type: TransactionType.expense,
      amount: 25.50,
      categoryId: 'transport',
      date: DateTime.now().subtract(const Duration(days: 2)),
      description: 'Uber to office',
    ),
    Transaction(
      id: '4',
      type: TransactionType.expense,
      amount: 120,
      categoryId: 'shopping',
      date: DateTime.now().subtract(const Duration(days: 3)),
      description: 'New shoes',
    ),
  ];

  List<Budget> get budgets => [
    Budget(categoryId: 'food', limit: 400),
    Budget(categoryId: 'shopping', limit: 300),
    Budget(categoryId: 'entertainment', limit: 150),
  ];
}