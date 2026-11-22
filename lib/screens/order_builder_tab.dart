import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/food_item.dart';
import '../theme/app_theme.dart';

/// Interactive screen allowing users to set a daily budget, pick a date,
/// and select menu items without exceeding their target cost.
class OrderBuilderTab extends StatefulWidget {
  const OrderBuilderTab({super.key});

  @override
  State<OrderBuilderTab> createState() => _OrderBuilderTabState();
}

class _OrderBuilderTabState extends State<OrderBuilderTab> {
  final TextEditingController _targetCostController =
  TextEditingController(text: '25.00');

  List<FoodItem> _menuItems = [];
  bool _isLoading = true;

  DateTime _selectedDate = DateTime.now();
  // Maps foodItem.id -> selected quantity
  final Map<int, int> _selectedQuantities = {};
  String? _budgetWarningMessage;

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  @override
  void dispose() {
    _targetCostController.dispose();
    super.dispose();
  }

  /// Loads all menu items from SQLite.
  Future<void> _loadMenuItems() async {
    final items = await DatabaseHelper.instance.getAllFoodItems();
    if (!mounted) return;
    setState(() {
      _menuItems = items;
      _isLoading = false;
    });
  }

  /// Parses the user-entered target cost per day (defaults to 0.0 if empty/invalid).
  double get _targetCost {
    return double.tryParse(_targetCostController.text.trim()) ?? 0.0;
  }

  /// Calculates the total cost of all currently selected food items.
  double get _currentTotalCost {
    double total = 0.0;
    for (final item in _menuItems) {
      final qty = _selectedQuantities[item.id] ?? 0;
      if (qty > 0) {
        total += item.cost * qty;
      }
    }
    return total;
  }

  /// Formats a DateTime object as YYYY-MM-DD.
  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Opens a Material date picker dialog to select the order plan date.
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Attempts to increment the quantity of a food item while enforcing target cost.
  void _incrementItem(FoodItem item) {
    if (item.id == null) return;

    final double target = _targetCost;
    if (target <= 0) {
      _showBudgetExceededAlert(
        'Please enter a valid target cost greater than \$0.00 first.',
      );
      return;
    }

    final double projectedTotal = _currentTotalCost + item.cost;
    // Use a tiny epsilon (0.001) to prevent floating-point rounding false positives
    if (projectedTotal > target + 0.001) {
      _showBudgetExceededAlert(
        'Cannot add "${item.name}" (\$${item.cost.toStringAsFixed(2)}). '
            'Total (\$${projectedTotal.toStringAsFixed(2)}) would exceed your '
            '\$${target.toStringAsFixed(2)} target cost!',
      );
      return;
    }

    setState(() {
      _budgetWarningMessage = null;
      _selectedQuantities[item.id!] = (_selectedQuantities[item.id!] ?? 0) + 1;
    });
  }

  /// Decrements the quantity of a selected food item.
  void _decrementItem(FoodItem item) {
    if (item.id == null) return;
    final int currentQty = _selectedQuantities[item.id!] ?? 0;
    if (currentQty <= 0) return;

    setState(() {
      _budgetWarningMessage = null;
      if (currentQty == 1) {
        _selectedQuantities.remove(item.id!);
      } else {
        _selectedQuantities[item.id!] = currentQty - 1;
      }
    });
  }

  /// Displays both an inline warning banner and a SnackBar when over-budget.
  void _showBudgetExceededAlert(String message) {
    setState(() {
      _budgetWarningMessage = message;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.mapleRed,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  /// Clears all current item selections.
  void _clearSelections() {
    setState(() {
      _selectedQuantities.clear();
      _budgetWarningMessage = null;
    });
  }

  /// Builds the top control card for Target Cost, Date Picker, and Live Summary.
  Widget _buildOrderControlsCard() {
    final double target = _targetCost;
    final double current = _currentTotalCost;
    final double remaining = (target - current).clamp(0.0, double.infinity);
    final bool isOverCurrentTarget = current > target + 0.001;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Target Cost Input
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: _targetCostController,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Target Cost (\$)',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) {
                      setState(() {
                        _budgetWarningMessage = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Date Picker Button
                Expanded(
                  flex: 6,
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      _formatDate(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppTheme.mapleRed),
                      foregroundColor: AppTheme.espressoBrown,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Running Cost Summary Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isOverCurrentTarget
                    ? Colors.red.shade50
                    : AppTheme.softSand,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Total',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.espressoBrown,
                        ),
                      ),
                      Text(
                        '\$${current.toStringAsFixed(2)} / \$${target.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isOverCurrentTarget
                              ? AppTheme.mapleRed
                              : AppTheme.espressoBrown,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Remaining Budget',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.espressoBrown,
                        ),
                      ),
                      Text(
                        isOverCurrentTarget
                            ? 'Over Budget!'
                            : '\$${remaining.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isOverCurrentTarget
                              ? AppTheme.mapleRed
                              : Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                  if (_selectedQuantities.isNotEmpty)
                    IconButton(
                      tooltip: 'Clear selections',
                      onPressed: _clearSelections,
                      icon: const Icon(Icons.refresh, color: AppTheme.mapleRed),
                    ),
                ],
              ),
            ),
            // Inline Over-Budget Warning Banner
            if (_budgetWarningMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.mapleRed),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.mapleRed,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _budgetWarningMessage!,
                        style: const TextStyle(
                          color: AppTheme.mapleRed,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildOrderControlsCard(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: _menuItems.length,
            itemBuilder: (context, index) {
              final FoodItem item = _menuItems[index];
              final int qty = _selectedQuantities[item.id] ?? 0;
              final bool canAffordOneMore =
                  (_currentTotalCost + item.cost) <= (_targetCost + 0.001);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: qty > 0 ? AppTheme.softSand : Colors.white,
                child: ListTile(
                  title: Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: qty > 0 ? FontWeight.bold : FontWeight.w600,
                      color: AppTheme.espressoBrown,
                    ),
                  ),
                  subtitle: Text(
                    '\$${item.cost.toStringAsFixed(2)} each',
                    style: const TextStyle(
                      color: AppTheme.mapleRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: qty > 0 ? AppTheme.mapleRed : Colors.grey,
                        onPressed: qty > 0 ? () => _decrementItem(item) : null,
                      ),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$qty',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.espressoBrown,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        color: canAffordOneMore
                            ? AppTheme.mapleRed
                            : Colors.grey.shade400,
                        // Still clickable when over budget so user receives explicit feedback
                        onPressed: () => _incrementItem(item),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}