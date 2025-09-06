import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fintrack/constants/app_colors.dart';
import 'package:fintrack/constants/categories.dart';
import 'package:fintrack/models/transaction.dart';
import 'package:fintrack/services/firestore_service.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends StatefulWidget {

  final Transaction? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  late bool _isEditMode;
  late TransactionType _selectedType;
  late String _selectedCategoryId;
  late DateTime _selectedDate;
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Check if we are in edit mode by seeing if a transaction was passed.
    _isEditMode = widget.transaction != null;

    if (_isEditMode) {
      // If editing, pre-fill all the fields with the existing data.
      final t = widget.transaction!;
      _selectedType = t.type;
      _selectedCategoryId = t.categoryId;
      _selectedDate = t.date;
      _descriptionController.text = t.description;
      _amountController.text = t.amount.toStringAsFixed(2);
    } else {
      // If adding a new transaction, set the default values.
      _selectedType = TransactionType.expense;
      _selectedCategoryId = allExpenseCategoryIds.first;
      _selectedDate = DateTime.now();
    }
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

  void _showCategoryPicker(BuildContext context, List<String> categoryIds) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: categoryIds.length,
          itemBuilder: (context, index) {
            final category = categories[categoryIds[index]]!;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedCategoryId = category.id;
                });
                Navigator.of(context).pop();
              },
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: category.color.withOpacity(0.2),
                    child: Icon(category.icon, color: category.color),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final availableCategories = _selectedType == TransactionType.income
        ? incomeCategoryIds
        : allExpenseCategoryIds;
    final selectedCategory = categories[_selectedCategoryId]!;

    return Container(
      padding: EdgeInsets.fromLTRB(24.0, 16.0, 24.0, MediaQuery.of(context).viewInsets.bottom + 24.0),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 5, margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(10)),
                ),
              ),

              SegmentedButton<TransactionType>(
                segments: const [
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
              const SizedBox(height: 24),

              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _selectedType == TransactionType.expense ? AppColors.expense : AppColors.income,
                ),
                inputFormatters: [ LengthLimitingTextInputFormatter(9) ],
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  prefixStyle: TextStyle(
                    color: _selectedType == TransactionType.expense ? AppColors.expense : AppColors.income,
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: '0.00',
                  border: InputBorder.none,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter an amount.';
                  final amount = double.tryParse(value);
                  if (amount == null) return 'Please enter a valid number.';
                  if (amount > 999999) return 'Amount cannot exceed \$999,999.';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _descriptionController,
                decoration: _buildInputDecoration(hint: 'Description', icon: Icons.description_outlined),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter a description.' : null,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildDetailRow(
                      icon: selectedCategory.icon,
                      title: 'Category',
                      value: selectedCategory.name,
                      onTap: () => _showCategoryPicker(context, availableCategories),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDetailRow(
                      icon: Icons.calendar_today_outlined,
                      title: 'Date',
                      value: DateFormat('MMM d, y').format(_selectedDate),
                      onTap: () => _selectDate(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final transactionToSave = Transaction(
                      id: _isEditMode ? widget.transaction!.id : '',
                      type: _selectedType,
                      amount: double.parse(_amountController.text),
                      categoryId: _selectedCategoryId,
                      date: _selectedDate,
                      description: _descriptionController.text,
                    );
                    showDialog(context: context, builder: (context) => const Center(child: CircularProgressIndicator()));

                    if (_isEditMode) {
                      await _firestoreService.updateTransaction(transactionToSave);
                    } else {
                      await _firestoreService.addTransaction(transactionToSave);
                    }

                    if (mounted) {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    }
                  }
                },
                icon: Icon(_isEditMode ? Icons.edit_rounded : Icons.check_circle_outline_rounded),
                label: Text(
                  _isEditMode ? 'Update Transaction' : 'Add Transaction',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hint, required IconData icon}) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade700),
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String title, required String value, required VoidCallback onTap}) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}