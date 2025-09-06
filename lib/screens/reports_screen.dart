// lib/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:fintrack/constants/app_colors.dart';
import 'package:fintrack/constants/categories.dart';
import 'package:fintrack/models/transaction.dart' as model;
import 'package:fintrack/services/firestore_service.dart';
import 'package:intl/intl.dart';

// Helper class to hold the calculated data for each category's expense.
class _CategoryExpense {
  final Category category;
  final double total;

  _CategoryExpense({required this.category, required this.total});
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
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
            return const Center(child: Text('No transaction data for reports.'));
          }

          final transactions = snapshot.data!;
          final allExpenses = transactions.where((t) => t.type == model.TransactionType.expense).toList();
          final totalExpense = allExpenses.fold(0.0, (sum, item) => sum + item.amount);

          final List<_CategoryExpense> expenseByCategory = [];
          if (totalExpense > 0) {
            for (var categoryId in expenseCategoryIds) {
              final category = categories[categoryId]!;
              final categoryTotal = allExpenses
                  .where((t) => t.categoryId == categoryId)
                  .fold(0.0, (sum, t) => sum + t.amount);

              if (categoryTotal > 0) {
                expenseByCategory.add(_CategoryExpense(
                  category: category,
                  total: categoryTotal,
                ));
              }
            }
            expenseByCategory.sort((a, b) => b.total.compareTo(a.total));
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSummaryCard(context, totalExpense),
              const SizedBox(height: 24),
              Text(
                'Expense Breakdown',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (expenseByCategory.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: Text('No expense data found.')),
                  ),
                )
              else
                ...expenseByCategory.map((item) => _buildExpenseBreakdownItem(context, item, totalExpense)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, double totalExpense) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return Card(
      elevation: 4,
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Total Expenses This Period', style: TextStyle(fontSize: 18, color: Colors.white70)),
            const SizedBox(height: 8),
            Text(currencyFormat.format(totalExpense), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseBreakdownItem(BuildContext context, _CategoryExpense item, double totalExpense) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final percentage = (item.total / totalExpense);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color secondaryTextColor = isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: item.category.color.withOpacity(0.2),
                  child: Icon(item.category.icon, color: item.category.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(item.category.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(item.total),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${(percentage * 100).toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 12, color: secondaryTextColor),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 8,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(item.category.color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}