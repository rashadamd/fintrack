// lib/screens/add_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:fintrack/constants/app_colors.dart';
import 'package:fintrack/constants/categories.dart';
import 'package:fintrack/models/transaction.dart';
import 'package:fintrack/services/firestore_service.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  // Form state
  TransactionType _selectedType = TransactionType.expense;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = allExpenseCategoryIds.first;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final availableCategories = _selectedType == TransactionType.income
        ? incomeCategoryIds
        : allExpenseCategoryIds;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24.0, 16.0, 24.0, MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Draggable Handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              Text('Add Transaction',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              // Amount Field - Specially styled for prominence
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _selectedType == TransactionType.expense ? AppColors.expense : AppColors.income,
                ),
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  prefixStyle: TextStyle(
                    color: _selectedType == TransactionType.expense ? AppColors.expense : AppColors.income,
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: '0.00',
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter an amount.';
                  if (double.tryParse(value) == null) return 'Please enter a valid number.';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              SegmentedButton<TransactionType>(
                segments: const <ButtonSegment<TransactionType>>[
                  ButtonSegment(value: TransactionType.expense, label: Text('Expense')),
                  ButtonSegment(value: TransactionType.income, label: Text('Income')),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                    _selectedCategoryId = (_selectedType == TransactionType.income ? incomeCategoryIds : allExpenseCategoryIds).first;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Other Fields
              TextFormField(
                controller: _descriptionController,
                decoration: _buildInputDecoration(label: 'Description', icon: Icons.description_outlined),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a description.';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: _buildInputDecoration(label: 'Category', icon: Icons.category_outlined),
                      items: availableCategories.map((categoryId) {
                        final category = categories[categoryId]!;
                        return DropdownMenuItem<String>(
                          value: categoryId,
                          child: Row(children: [
                            Icon(category.icon, color: category.color, size: 20),
                            const SizedBox(width: 8),
                            Text(category.name),
                          ]),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() { _selectedCategoryId = newValue; });
                      },
                      validator: (value) => value == null ? 'Please select a category.' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      readOnly: true,
                      controller: TextEditingController(text: DateFormat('MMM d').format(_selectedDate)),
                      decoration: _buildInputDecoration(label: 'Date', icon: Icons.calendar_today_outlined),
                      onTap: () => _selectDate(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final newTransaction = Transaction(
                      id: '',
                      type: _selectedType,
                      amount: double.parse(_amountController.text),
                      categoryId: _selectedCategoryId!,
                      date: _selectedDate,
                      description: _descriptionController.text,
                    );

                    showDialog(context: context, builder: (context) => const Center(child: CircularProgressIndicator()));
                    await _firestoreService.addTransaction(newTransaction);

                    if (mounted) {
                      Navigator.of(context).pop(); // Close loading indicator
                      Navigator.of(context).pop(); // Close bottom sheet
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add Transaction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modern, "filled" input field styling
  InputDecoration _buildInputDecoration({required String label, required IconData icon}) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }
}