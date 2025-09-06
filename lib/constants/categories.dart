// lib/constants/categories.dart
import 'package:flutter/material.dart';
import 'package:fintrack/constants/app_colors.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

// This is the direct equivalent of your CATEGORIES object in TypeScript
final Map<String, Category> categories = {
  'food': const Category(id: 'food', name: 'Food', icon: Icons.fastfood, color: AppColors.food),
  'transport': const Category(id: 'transport', name: 'Transport', icon: Icons.directions_car, color: AppColors.transport),
  'salary': const Category(id: 'salary', name: 'Salary', icon: Icons.attach_money, color: AppColors.salary),
  'shopping': const Category(id: 'shopping', name: 'Shopping', icon: Icons.shopping_cart, color: AppColors.shopping),
  'entertainment': const Category(id: 'entertainment', name: 'Entertainment', icon: Icons.movie, color: AppColors.entertainment),
  'utilities': const Category(id: 'utilities', name: 'Utilities', icon: Icons.receipt_long, color: AppColors.utilities),
  'freelance': const Category(id: 'freelance', name: 'Freelance', icon: Icons.work, color: AppColors.freelance),
  'health': const Category(id: 'health', name: 'Health', icon: Icons.health_and_safety, color: AppColors.health),
};

final List<String> expenseCategoryIds = [
  'food',
  'transport',
  'shopping',
  'entertainment',
  'utilities',
  'health',
];

final List<String> incomeCategoryIds = [
  'salary',
  'freelance',
];

// Re-defining this to be a standalone list for clarity, even if it's the same
final List<String> allExpenseCategoryIds = [
  'food',
  'transport',
  'shopping',
  'entertainment',
  'utilities',
  'health',
];