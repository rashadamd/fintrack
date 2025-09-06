// lib/screens/budget_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fintrack/constants/app_colors.dart';
import 'package:fintrack/constants/categories.dart';
import 'package:fintrack/models/budget.dart' as model;
import 'package:fintrack/models/transaction.dart' as model_transaction;
import 'package:fintrack/services/firestore_service.dart';
import 'package:intl/intl.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _editingCategoryId;
  final TextEditingController _budgetController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _changeMonth(int increment) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + increment, 1);
    });
  }

  void _updateBudget(String categoryId) async {
    if (_formKey.currentState!.validate()) {
      final limit = double.tryParse(_budgetController.text) ?? 0.0;
      showDialog(context: context, builder: (context) => const Center(child: CircularProgressIndicator()));
      await _firestoreService.updateBudget(model.Budget(categoryId: categoryId, limit: limit));
      if (mounted) Navigator.of(context).pop();
      setState(() { _editingCategoryId = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color secondaryTextColor = isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Budgets'),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          Expanded(
            child: StreamBuilder<List<model_transaction.Transaction>>(
              stream: _firestoreService.getTransactions(month: _selectedMonth),
              builder: (context, transactionSnapshot) {
                if (transactionSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final transactions = transactionSnapshot.data ?? [];

                return StreamBuilder<List<model.Budget>>(
                  stream: _firestoreService.getBudgets(),
                  builder: (context, budgetSnapshot) {
                    if (budgetSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final budgets = budgetSnapshot.data ?? [];

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: expenseCategoryIds.length,
                      itemBuilder: (context, index) {
                        final categoryId = expenseCategoryIds[index];
                        final category = categories[categoryId]!;
                        final budget = budgets.firstWhere((b) => b.categoryId == categoryId, orElse: () => model.Budget(categoryId: categoryId, limit: 0));
                        final isEditing = _editingCategoryId == categoryId;

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: isEditing
                                ? _buildEditView(category, isDarkMode)
                                : _buildDisplayView(context, category, budget, transactions, currencyFormat, secondaryTextColor),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
            onPressed: () => _changeMonth(1),
          ),
        ],
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
                CircleAvatar(backgroundColor: category.color.withOpacity(0.2), child: Icon(category.icon, color: category.color, size: 20)),
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
            value: percentage, minHeight: 10,
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

  Widget _buildEditView(Category category, bool isDarkMode) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Set budget for ${category.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _budgetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            autofocus: true,
            inputFormatters: [ FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6) ],
            decoration: InputDecoration(
              prefixText: '\$ ',
              hintText: 'Enter budget limit',
              filled: true,
              fillColor: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final amount = double.tryParse(value);
                if (amount == null) return 'Invalid number';
                if (amount > 999999) return 'Limit cannot exceed \$999,999.';
              }
              return null;
            },
            onFieldSubmitted: (_) => _updateBudget(category.id),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => setState(() => _editingCategoryId = null), child: const Text('Cancel')),
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
      ),
    );
  }
}