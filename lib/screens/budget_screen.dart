// lib/screens/budget_screen.dart
import 'package:flutter/material.dart';
import 'package:fintrack/constants/categories.dart';
import 'package:fintrack/models/budget.dart' as model;
import 'package:fintrack/models/transaction.dart' as model_transaction;
import 'package:fintrack/services/firestore_service.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _editingCategoryId;
  final TextEditingController _budgetController = TextEditingController();

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _updateBudget(String categoryId) async {
    final limit = double.tryParse(_budgetController.text) ?? 0.0;
    showDialog(context: context, builder: (context) => const Center(child: CircularProgressIndicator()));
    await _firestoreService.updateBudget(model.Budget(categoryId: categoryId, limit: limit));
    if (mounted) Navigator.of(context).pop();
    setState(() {
      _editingCategoryId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color secondaryTextColor = isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: StreamBuilder<List<model_transaction.Transaction>>(
        stream: _firestoreService.getTransactions(),
        builder: (context, transactionSnapshot) {
          if (transactionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (transactionSnapshot.hasError) {
            return const Center(child: Text('Error fetching transactions.'));
          }
          final transactions = transactionSnapshot.data ?? [];

          return StreamBuilder<List<model.Budget>>(
            stream: _firestoreService.getBudgets(),
            builder: (context, budgetSnapshot) {
              if (budgetSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (budgetSnapshot.hasError) {
                return const Center(child: Text('Error fetching budgets.'));
              }
              final budgets = budgetSnapshot.data ?? [];

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: expenseCategoryIds.length,
                itemBuilder: (context, index) {
                  final categoryId = expenseCategoryIds[index];
                  final category = categories[categoryId]!;

                  final budget = budgets.firstWhere(
                        (b) => b.categoryId == categoryId,
                    orElse: () => model.Budget(categoryId: categoryId, limit: 0),
                  );

                  final spent = transactions
                      .where((t) => t.categoryId == categoryId && t.type == model_transaction.TransactionType.expense)
                      .fold(0.0, (sum, t) => sum + t.amount);

                  final isEditing = _editingCategoryId == categoryId;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: isEditing
                          ? _buildEditView(category)
                          : _buildDisplayView(context, category, budget, transactions, currencyFormat, secondaryTextColor),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDisplayView(BuildContext context, Category category, model.Budget budget, List<model_transaction.Transaction> allTransactions, NumberFormat format, Color secondaryColor) {
    return InkWell(
      onTap: () {
        setState(() {
          _editingCategoryId = category.id;
          _budgetController.text = budget.limit > 0 ? budget.limit.toStringAsFixed(0) : '';
        });
      },
      child: _buildBudgetItem(context, budget, allTransactions, format, secondaryColor),
    );
  }


  Widget _buildBudgetItem(BuildContext context, model.Budget budget, List<model_transaction.Transaction> allTransactions, NumberFormat format, Color secondaryColor) {
    final category = categories[budget.categoryId]!;
    final spent = allTransactions
        .where((t) => t.categoryId == budget.categoryId && t.type == model_transaction.TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final percentage = (budget.limit > 0) ? (spent / budget.limit).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: category.color.withOpacity(0.2),
                  child: Icon(category.icon, color: category.color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Text('${format.format(spent)} / ${format.format(budget.limit)}', style: TextStyle(color: secondaryColor, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 10,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
            valueColor: AlwaysStoppedAnimation<Color>(category.color),
          ),
        ),
        if (budget.limit == 0)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('Tap to set a budget', style: TextStyle(color: secondaryColor, fontSize: 12)),
          )
      ],
    );
  }

  // Redesigned Edit View
  Widget _buildEditView(Category category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Set budget for ${category.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        TextField(
          controller: _budgetController,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          autofocus: true,
          decoration: InputDecoration(
            prefixText: '\$ ',
            labelText: 'Budget Limit',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) => _updateBudget(category.id),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => setState(() => _editingCategoryId = null),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _updateBudget(category.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save'),
            ),
          ],
        )
      ],
    );
  }
}