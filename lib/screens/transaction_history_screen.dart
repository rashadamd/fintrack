// lib/screens/transaction_history_screen.dart
import 'package:flutter/material.dart';
import 'package:fintrack/constants/app_colors.dart';
import 'package:fintrack/constants/categories.dart';
import 'package:fintrack/models/transaction.dart' as model;
import 'package:fintrack/screens/add_transaction_screen.dart'; // Import for navigation
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color secondaryTextColor = isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: StreamBuilder<List<model.Transaction>>(
        stream: _firestoreService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No transactions yet.'));
          }

          final transactions = snapshot.data!;
          final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];

              // --- WRAP THE CARD IN A Dismissible WIDGET FOR SWIPING ---
              return Dismissible(
                key: Key(transaction.id), // Unique key is essential
                direction: DismissDirection.endToStart, // Swipe from right to left

                // Confirmation dialog before deleting
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirm Delete"),
                        content: const Text("Are you sure you want to delete this transaction? This action cannot be undone."),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false), // Cancels dismiss
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true), // Confirms dismiss
                            child: const Text("Delete"),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                          ),
                        ],
                      );
                    },
                  );
                },

                // Action to perform after confirmed dismissal
                onDismissed: (direction) {
                  _firestoreService.deleteTransaction(transaction.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction deleted')),
                  );
                },

                // The background that shows up when swiping
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),

                // The actual transaction item card
                child: _buildTransactionItem(context, transaction, currencyFormat, secondaryTextColor),
              );
            },
          );
        },
      ),
    );
  }

  // Helper widget - NOW WITH onTap FOR EDITING!
  Widget _buildTransactionItem(BuildContext context, model.Transaction transaction, NumberFormat format, Color secondaryColor) {
    final category = categories[transaction.categoryId]!;
    final isIncome = transaction.type == model.TransactionType.income;

    return Card(
      child: ListTile(
        onTap: () {
          // --- NAVIGATION TO EDIT SCREEN ---
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            // Pass the transaction to the AddTransactionScreen
            builder: (BuildContext context) => AddTransactionScreen(transaction: transaction),
          );
        },
        leading: CircleAvatar(
          backgroundColor: category.color.withOpacity(0.2),
          child: Icon(category.icon, color: category.color, size: 24),
        ),
        title: Text(transaction.description, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(DateFormat.yMMMd().format(transaction.date), style: TextStyle(color: secondaryColor)),
        trailing: Text(
          '${isIncome ? '+' : '-'}${format.format(transaction.amount)}',
          style: TextStyle(
            color: isIncome ? AppColors.income : AppColors.expense,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}