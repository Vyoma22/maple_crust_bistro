import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/food_item.dart';
import '../models/order_plan.dart';
import '../theme/app_theme.dart';

/// Interactive screen allowing users to set a daily budget, pick a date,
/// select menu items within budget, and save the order plan to SQLite.
class OrderBuilderTab extends StatefulWidget {
  const OrderBuilderTab({super.key});

  @override
  State<OrderBuilderTab> createState() => _OrderBuilderTabState();
}

class _OrderBuilderTabState extends State<OrderBuilderTab> {
  final TextEditingController _targetCostController =
  TextEditingController(text: '25.00');

  // Tracks the confirmed target cost currently locked in for the order
  double _activeTargetCost = 25.00;
  String? _targetInputError;

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

  /// Parses the raw value currently typed in the Target Cost text field.
  double? get _parsedInputTargetCost {
    final text = _targetCostController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  /// Determines whether the 'Set' button should be enabled:
  /// True only if the typed value is valid (> 0) and differs from _activeTargetCost.
  bool get _canSetNewTargetCost {
    final parsed = _parsedInputTargetCost;
    if (parsed == null || parsed <= 0) return false;
    return (parsed - _activeTargetCost).abs() > 0.001;
  }

  /// Validates the text field whenever the user types and updates button state.
  void _onTargetCostChanged(String value) {
    final parsed = double.tryParse(value.trim());
    setState(() {
      if (value.trim().isEmpty || parsed == null || parsed <= 0) {
        _targetInputError = 'Enter a target cost greater than \$0.00';
      } else {
        _targetInputError = null;
      }
    });
  }

  /// Locks in the new target cost when the user taps the 'Set' button.
  void _applyTargetCost() {
    final parsed = _parsedInputTargetCost;
    if (parsed == null || parsed <= 0) {
      setState(() {
        _targetInputError = 'Enter a target cost greater than \$0.00';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _activeTargetCost = double.parse(parsed.toStringAsFixed(2));
      _targetCostController.text = _activeTargetCost.toStringAsFixed(2);
      _targetInputError = null;

      if (_currentTotalCost > _activeTargetCost + 0.001) {
        _budgetWarningMessage =
        'Selected items (\$${_currentTotalCost.toStringAsFixed(2)}) exceed '
            'your new target cost (\$${_activeTargetCost.toStringAsFixed(2)}). '
            'Remove items before saving.';
      } else {
        _budgetWarningMessage = null;
      }
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Target cost set to \$${_activeTargetCost.toStringAsFixed(2)}',
          ),
          backgroundColor: AppTheme.espressoBrown,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
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

    if (_activeTargetCost <= 0) {
      _showBudgetExceededAlert(
        'Please set a valid target cost greater than \$0.00 first.',
      );
      return;
    }

    final double projectedTotal = _currentTotalCost + item.cost;
    if (projectedTotal > _activeTargetCost + 0.001) {
      _showBudgetExceededAlert(
        'Cannot add "${item.name}" (\$${item.cost.toStringAsFixed(2)}). '
            'Total (\$${projectedTotal.toStringAsFixed(2)}) would exceed your '
            '\$${_activeTargetCost.toStringAsFixed(2)} target cost!',
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
      if (currentQty == 1) {
        _selectedQuantities.remove(item.id!);
      } else {
        _selectedQuantities[item.id!] = currentQty - 1;
      }

      if (_currentTotalCost <= _activeTargetCost + 0.001) {
        _budgetWarningMessage = null;
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

  /// Validates and saves the current order plan into the SQLite database.
  Future<void> _saveOrderPlan() async {
    final double total = _currentTotalCost;

    if (_activeTargetCost <= 0) {
      _showBudgetExceededAlert('Set a valid target cost greater than \$0.00 before saving.');
      return;
    }

    if (_selectedQuantities.isEmpty) {
      _showBudgetExceededAlert('Select at least one food item before saving.');
      return;
    }

    if (total > _activeTargetCost + 0.001) {
      _showBudgetExceededAlert(
        'Total (\$${total.toStringAsFixed(2)}) exceeds target cost '
            '(\$${_activeTargetCost.toStringAsFixed(2)}). Remove items or raise your target.',
      );
      return;
    }

    final List<FoodItem> chosenItems = [];
    for (final item in _menuItems) {
      final int qty = _selectedQuantities[item.id] ?? 0;
      for (int i = 0; i < qty; i++) {
        chosenItems.add(item);
      }
    }

    final String formattedDate = _formatDate(_selectedDate);
    final OrderPlan newPlan = OrderPlan(
      date: formattedDate,
      targetCost: _activeTargetCost,
      totalCost: total,
      items: chosenItems,
    );

    await DatabaseHelper.instance.insertOrderPlan(newPlan);
    if (!mounted) return;

    _clearSelections();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Saved order plan for $formattedDate (\$${total.toStringAsFixed(2)})!',
          ),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Builds the top control card for Target Cost + Set Button, Date Picker, and Live Summary.
  Widget _buildOrderControlsCard() {
    final double current = _currentTotalCost;
    final double remaining =
    (_activeTargetCost - current).clamp(0.0, double.infinity);
    final bool isOverCurrentTarget = current > _activeTargetCost + 0.001;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Target Cost Input + Validation
                Expanded(
                  flex: 6,
                  child: TextField(
                    controller: _targetCostController,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Target Cost (\$)',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      errorText: _targetInputError,
                    ),
                    onChanged: _onTargetCostChanged,
                  ),
                ),
                const SizedBox(width: 8),
                // 'Set' Button (Enabled only when valid > 0 and changed)
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _canSetNewTargetCost ? _applyTargetCost : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text(
                      'Set',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Date Picker Button
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        side: const BorderSide(color: AppTheme.mapleRed),
                        foregroundColor: AppTheme.espressoBrown,
                      ),
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
                        'Selected Total / Set Target',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.espressoBrown,
                        ),
                      ),
                      Text(
                        '\$${current.toStringAsFixed(2)} / \$${_activeTargetCost.toStringAsFixed(2)}',
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
                  (_currentTotalCost + item.cost) <= (_activeTargetCost + 0.001);

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
                        onPressed: () => _incrementItem(item),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Bottom Save Order Plan Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppTheme.softSand, width: 1.5),
            ),
          ),
          child: ElevatedButton.icon(
            onPressed: _saveOrderPlan,
            icon: const Icon(Icons.save_alt),
            label: Text(
              'Save Order Plan (\$${_currentTotalCost.toStringAsFixed(2)})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}