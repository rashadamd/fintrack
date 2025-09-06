// lib/screens/reports_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fintrack/constants/app_colors.dart';
import 'package:fintrack/constants/categories.dart';
import 'package:fintrack/models/transaction.dart' as model;
import 'package:fintrack/services/firestore_service.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _changeMonth(int increment) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + increment, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Reports'),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          Expanded(
            child: StreamBuilder<List<model.Transaction>>(
              stream: _firestoreService.getTransactions(month: _selectedMonth),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No transactions for this month."));
                }

                final allExpenses = snapshot.data!.where((t) => t.type == model.TransactionType.expense).toList();
                final totalExpense = allExpenses.fold(0.0, (sum, item) => sum + item.amount);

                if (totalExpense == 0) {
                  return const Center(child: Text("No expenses for this month."));
                }

                Map<String, double> spendingByCategory = {};
                for (var expense in allExpenses) {
                  spendingByCategory.update(
                    expense.categoryId,
                        (value) => value + expense.amount,
                    ifAbsent: () => expense.amount,
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildChart(context, spendingByCategory, totalExpense),
                    const SizedBox(height: 24),
                    _buildLegend(context, spendingByCategory, totalExpense),
                  ],
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

  Widget _buildChart(BuildContext context, Map<String, double> data, double total) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(touchCallback: (FlTouchEvent event, pieTouchResponse) {}),
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: data.entries.map((entry) {
            final category = categories[entry.key]!;
            final percentage = (entry.value / total) * 100;
            return PieChartSectionData(
              color: category.color,
              value: entry.value,
              title: '${percentage.toStringAsFixed(0)}%',
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context, Map<String, double> data, double total) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final sortedEntries = data.entries.toList()..sort((a,b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: sortedEntries.map((entry) {
            final category = categories[entry.key]!;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Container(width: 16, height: 16, color: category.color),
                  const SizedBox(width: 12),
                  Expanded(child: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                  Text(currencyFormat.format(entry.value)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}