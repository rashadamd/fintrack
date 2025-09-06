import 'package:flutter/material.dart';
import 'package:fintrack/constants/app_colors.dart';
import '../constants/categories.dart';
import 'package:fintrack/models/transaction.dart' as model;
import 'package:fintrack/models/budget.dart' as model_budget;
import 'package:fintrack/screens/settings_screen.dart';
import 'package:fintrack/services/auth_service.dart';
import 'package:fintrack/services/firestore_service.dart';
import 'package:intl/intl.dart';

class _DashboardBudgetView {
  final model_budget.Budget budget;
  final double spendingPercentage;

  _DashboardBudgetView({required this.budget, required this.spendingPercentage});
}

class DashboardScreen extends StatefulWidget {
  final void Function(int) onNavigate;
  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  // State variable to track the selected month
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  // Method to change the month
  void _changeMonth(int increment) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + increment, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color primaryTextColor = isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildHeader(context, _authService.currentUser?.displayName ?? "User", primaryTextColor),
            const SizedBox(height: 16),
            _buildMonthSelector(),
            Expanded(
              child: StreamBuilder<List<model.Transaction>>(
                stream: _firestoreService.getTransactions(month: _selectedMonth),
                builder: (context, transactionSnapshot) {
                  if (transactionSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final transactions = transactionSnapshot.data ?? [];

                  return StreamBuilder<List<model_budget.Budget>>(
                    stream: _firestoreService.getBudgets(),
                    builder: (context, budgetSnapshot) {
                      if (budgetSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final budgets = budgetSnapshot.data ?? [];

                      if (transactions.isEmpty) {
                        return _buildEmptyDashboard(context);
                      }

                      //  calculation logic
                      final totalIncome = transactions.where((t) => t.type == model.TransactionType.income).fold(0.0, (sum, t) => sum + t.amount);
                      final totalExpense = transactions.where((t) => t.type == model.TransactionType.expense).fold(0.0, (sum, t) => sum + t.amount);
                      final balance = totalIncome - totalExpense;
                      final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
                      final recentTransactions = transactions.take(3).toList();

                      final List<_DashboardBudgetView> dashboardBudgets = budgets.map((budget) {
                        final spent = transactions.where((t) => t.categoryId == budget.categoryId && t.type == model.TransactionType.expense).fold(0.0, (sum, t) => sum + t.amount);
                        final percentage = (budget.limit > 0) ? (spent / budget.limit) : 0.0;
                        return _DashboardBudgetView(budget: budget, spendingPercentage: percentage);
                      }).toList();
                      dashboardBudgets.sort((a, b) => b.spendingPercentage.compareTo(a.spendingPercentage));
                      final topBudgets = dashboardBudgets.take(3).toList();

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        children: [
                          _buildBalanceCard(context, currencyFormat, balance, totalIncome, totalExpense),
                          const SizedBox(height: 24),
                          _buildSectionHeader(context, 'Recent Transactions', 'View All', () => widget.onNavigate(1), primaryTextColor),
                          ...recentTransactions.map((t) => _buildTransactionItem(context, t, currencyFormat,primaryTextColor)),
                          const SizedBox(height: 24),
                          _buildSectionHeader(context, 'Budgets', 'Manage', () => widget.onNavigate(2), primaryTextColor),
                          if (topBudgets.isEmpty)
                            const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text("No budgets set."))))
                          else
                          ...topBudgets.map((db) => _buildBudgetItem(context, db.budget, transactions, currencyFormat, primaryTextColor)),                          const SizedBox(height: 80),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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

  Widget _buildHeader(BuildContext context, String userName, Color textColor) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello,', style: TextStyle(fontSize: 18, color: textColor.withOpacity(0.7))),
              Text(userName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
          child: CircleAvatar(
            radius: 25,
            // Use a subtle background color that works in both themes
            backgroundColor: isDarkMode ? AppColors.darkCard : Colors.white,
            child: Icon(
              Icons.settings_rounded, // A more modern, rounded icon
              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, NumberFormat format, double balance, double income, double expense) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Total Balance', style: TextStyle(fontSize: 16, color: Colors.white70)),
            Text(format.format(balance), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildIncomeExpenseItem(context, 'Income', format.format(income), Icons.arrow_upward_rounded),
                _buildIncomeExpenseItem(context, 'Expense', format.format(expense), Icons.arrow_downward_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeExpenseItem(BuildContext context, String title, String amount, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            Text(amount, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String buttonText, VoidCallback onTap, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
        TextButton(onPressed: onTap, child: Text(buttonText, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
      ],
    );
  }

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

  Widget _buildBudgetItem(BuildContext context, model_budget.Budget budget, List<model.Transaction> allTransactions, NumberFormat format, Color secondaryColor) {
    final category = categories[budget.categoryId]!;
    final spent = allTransactions
        .where((t) => t.categoryId == budget.categoryId && t.type == model.TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final percentage = (spent / budget.limit).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(category.color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDashboard(BuildContext context) {
    // This is a simplified version for when the ListView is removed
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No transactions for this month. Tap the "+" button to get started!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}