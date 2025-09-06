// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:fintrack/constants/app_colors.dart';
import 'package:fintrack/screens/add_transaction_screen.dart';
import 'package:fintrack/screens/budget_screen.dart';
import 'package:fintrack/screens/dashboard_screen.dart';
import 'package:fintrack/screens/reports_screen.dart';
import 'package:fintrack/screens/transaction_history_screen.dart';
// Import the new package
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions;

  // List of icons to display in the navigation bar
  final List<IconData> _iconList = [
    Icons.dashboard_outlined,
    Icons.history_outlined,
    Icons.pie_chart_outline,
    Icons.bar_chart_outlined,
  ];

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

      // The FloatingActionButton remains the same
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent, // Make sheet background transparent
            builder: (BuildContext context) => const AddTransactionScreen(),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // This is the new, redesigned navigation bar
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: _iconList,
        activeIndex: _selectedIndex,
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.softEdge,
        onTap: _onItemTapped,
        // --- Styling to match our theme ---
        backgroundColor: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
        activeColor: AppColors.primary,
        inactiveColor: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        shadow: BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
        ),
      ),
    );
  }
}