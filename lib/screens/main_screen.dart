// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:fintrack/constants/app_colors.dart';
import 'package:fintrack/screens/add_transaction_screen.dart';
import 'package:fintrack/screens/budget_screen.dart';
import 'package:fintrack/screens/dashboard_screen.dart';
import 'package:fintrack/screens/reports_screen.dart';
import 'package:fintrack/screens/transaction_history_screen.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      DashboardScreen(onNavigate: _onItemTapped),
      const TransactionHistoryScreen(),
      const BudgetScreen(),
      const ReportsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (BuildContext context) => const AddTransactionScreen(),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: AppColors.primary.withOpacity(0.2),
              hoverColor: AppColors.primary.withOpacity(0.1),
              gap: 8,
              activeColor: Colors.white,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: AppColors.primary,
              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              tabs: const [
                GButton(icon: Icons.dashboard_outlined, text: 'Dashboard'),
                GButton(icon: Icons.history_outlined, text: 'History'),
                GButton(icon: Icons.pie_chart_outline, text: 'Budgets'),
                GButton(icon: Icons.bar_chart_outlined, text: 'Reports'),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}