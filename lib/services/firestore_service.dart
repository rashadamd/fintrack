import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fintrack/models/transaction.dart' as model;
import 'package:fintrack/services/auth_service.dart';
import 'package:fintrack/models/budget.dart' as model_budget;

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  String? get _userId => _authService.currentUser?.uid;

  // --- Transactions ---

  Future<void> addTransaction(model.Transaction transaction) async {
    if (_userId == null) return;

    await _db
        .collection('users')
        .doc(_userId)
        .collection('transactions')
        .add({
      'type': transaction.type.name,
      'amount': transaction.amount,
      'categoryId': transaction.categoryId,
      'date': Timestamp.fromDate(transaction.date),
      'description': transaction.description,
    });
  }

  Future<void> updateTransaction(model.Transaction transaction) async {
    if (_userId == null) return;

    await _db
        .collection('users')
        .doc(_userId)
        .collection('transactions')
        .doc(transaction.id)
        .update({
      'type': transaction.type.name,
      'amount': transaction.amount,
      'categoryId': transaction.categoryId,
      'date': Timestamp.fromDate(transaction.date),
      'description': transaction.description,
    });
  }

  Future<void> deleteTransaction(String transactionId) async {
    if (_userId == null) return;

    await _db
        .collection('users')
        .doc(_userId)
        .collection('transactions')
        .doc(transactionId)
        .delete();
  }

  Stream<List<model.Transaction>> getTransactions({required DateTime month}) {
    if (_userId == null) return Stream.value([]);

    DateTime startOfMonth = DateTime(month.year, month.month, 1);
    DateTime endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59); // End of the last day of the month

    return _db
        .collection('users')
        .doc(_userId)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        return model.Transaction(
          id: doc.id,
          type: model.TransactionType.values.byName(data['type']),
          amount: data['amount'],
          categoryId: data['categoryId'],
          date: (data['date'] as Timestamp).toDate(),
          description: data['description'],
        );
      }).toList();
    });
  }

  // --- Budgets ---

  Future<void> updateBudget(model_budget.Budget budget) async {
    if (_userId == null) return;

    await _db
        .collection('users')
        .doc(_userId)
        .collection('budgets')
        .doc(budget.categoryId)
        .set({
      'limit': budget.limit,
    });
  }

  Stream<List<model_budget.Budget>> getBudgets() {
    if (_userId == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(_userId)
        .collection('budgets')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return model_budget.Budget(
          categoryId: doc.id,
          limit: doc.data()['limit'],
        );
      }).toList();
    });
  }
}