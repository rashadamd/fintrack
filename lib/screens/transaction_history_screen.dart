// lib/screens/transaction_history_screen.dart
import 'package:flutter/material.dart';
import 'package:fintrack/constants/app_colors.dart';
import 'package:fintrack/constants/categories.dart';
import 'package:fintrack/models/transaction.dart' as model;
import 'package:fintrack/screens/add_transaction_screen.dart';
import 'package:fintrack/services/firestore_service.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String? _selectedCategoryId;

  void _changeMonth(int increment) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + increment, 1);
    });
  }

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
      body: Column(
        children: [
          _buildMonthSelector(),
          _buildCategoryFilter(),
          Expanded(
            child: StreamBuilder<List<model.Transaction>>(
              stream: _firestoreService.getTransactions(month: _selectedMonth),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final transactions = snapshot.data?.where((t) {
                  return _selectedCategoryId == null || t.categoryId == _selectedCategoryId;
                }).toList() ?? [];

                if (transactions.isEmpty) {
                  return const Center(child: Text("No transactions found for this selection."));
                }

                final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return Dismissible(
                      key: Key(transaction.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: const Text("Confirm Delete"),
                            content: const Text("Are you sure you want to delete this transaction?"),
                            actions: <Widget>[
                              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
                              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Delete"), style: TextButton.styleFrom(foregroundColor: Colors.red)),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        _firestoreService.deleteTransaction(transaction.id);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: _buildTransactionItem(context, transaction, currencyFormat, secondaryTextColor),
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

  Widget _buildCategoryFilter() {
    // We combine all categories for the filter
    final allCategoryIds = (incomeCategoryIds + expenseCategoryIds).toSet().toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          FilterChip(
            label: const Text("All"),
            selected: _selectedCategoryId == null,
            onSelected: (bool selected) {
              setState(() { _selectedCategoryId = null; });
            },
          ),
          ...allCategoryIds.map((id) {
            final category = categories[id]!;
            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: FilterChip(
                label: Text(category.name),
                avatar: Icon(category.icon, size: 16),
                selected: _selectedCategoryId == id,
                onSelected: (bool selected) {
                  setState(() { _selectedCategoryId = selected ? id : null; });
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, model.Transaction transaction, NumberFormat format, Color secondaryColor) {
    final category = categories[transaction.categoryId]!;
    final isIncome = transaction.type == model.TransactionType.income;

    return Card(
      child: ListTile(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
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