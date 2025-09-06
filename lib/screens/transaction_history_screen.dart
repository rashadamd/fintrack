// lib/screens/transaction_history_screen.dart
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fintrack/constants/app_colors.dart';
import 'package:fintrack/constants/categories.dart';
import 'package:fintrack/models/transaction.dart' as model;
import 'package:fintrack/services/firestore_service.dart';
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
    // Determine secondary text color from theme
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
          if (snapshot.hasError) {
            return const Center(child: Text('An error occurred.'));
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
              // We reuse the beautifully designed transaction item widget
              return _buildTransactionItem(context, transaction, currencyFormat, secondaryTextColor);
            },
          );
        },
      ),
    );
  }

  // Helper widget copied directly from our redesigned Dashboard
  Widget _buildTransactionItem(BuildContext context, model.Transaction transaction, NumberFormat format, Color secondaryColor) {
    final category = categories[transaction.categoryId]!;
    final isIncome = transaction.type == model.TransactionType.income;

    return Card(
      child: ListTile(
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