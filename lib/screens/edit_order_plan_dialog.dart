import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/food_item.dart';
import '../models/order_plan.dart';
import '../theme/app_theme.dart';

/// Dialog for updating an existing OrderPlan's date, target cost, and food items.
class EditOrderPlanDialog extends StatefulWidget {
  final OrderPlan plan;

  const EditOrderPlanDialog({super.key, required this.plan});

  @override
  State<EditOrderPlanDialog> createState() => _EditOrderPlanDialogState();
}

class _EditOrderPlanDialogState extends State<EditOrderPlanDialog> {
  late TextEditingController _targetCostController;
  late double _activeTargetCost;
  String? _targetInputError;

  late DateTime _selectedDate;
  List<FoodItem> _menuItems = [];
  bool _isLoading = true;

  // Maps foodItem.id -> quantity
  final Map<int, int> _quantities = {};
  String? _warningMessage;

  @override
  void initState() {
    super.initState();
    _activeTargetCost = widget.plan.targetCost;
    _targetCostController =
        TextEditingController(text: _activeTargetCost.toStringAsFixed(2));
    _selectedDate = DateTime.tryParse(widget.plan.date) ?? DateTime.now();
    _loadMenuAndMapExistingItems();
  }

  @override
  void dispose() {
    _targetCostController.dispose();
    super.dispose();
  }

  /// Loads current menu items and populates quantities from the existing OrderPlan.
  Future<void> _loadMenuAndMapExistingItems() async {
    final menu = await DatabaseHelper.instance.getAllFoodItems();

    // Count existing items by ID (falling back to name match if edited)
    for (final savedItem in widget.plan.items) {
      FoodItem? match;
      if (savedItem.id != null &&
          menu.any((m) => m.id == savedItem.id)) {
        match = menu.firstWhere((m) => m.id == savedItem.id);
      } else if (menu.any((m) => m.name == savedItem.name)) {
        match = menu.firstWhere((m) => m.name == savedItem.name);
      }
      if (match?.id != null) {
        _quantities[match!.id!] = (_quantities[match.id!] ?? 0) + 1;
      }
    }

    if (!mounted) return;
    setState(() {
      _menuItems = menu;
      _isLoading = false;
    });
  }

  double? get _parsedInputTargetCost {
    final text = _targetCostController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  bool get _canSetNewTarget {
    final parsed = _parsedInputTargetCost;
    if (parsed == null || parsed <= 0) return false;
    return (parsed - _activeTargetCost).abs() > 0.001;
  }

  void _applyTargetCost() {
    final parsed = _parsedInputTargetCost;
    if (parsed == null || parsed <= 0) {
      setState(() {
        _targetInputError = 'Must be > \$0.00';
      });
      return;
    }
    setState(() {
      _activeTargetCost = double.parse(parsed.toStringAsFixed(2));
      _targetCostController.text = _activeTargetCost.toStringAsFixed(2);
      _targetInputError = null;
      if (_currentTotalCost > _activeTargetCost + 0.001) {
        _warningMessage = 'Total exceeds new target cost. Remove items first.';
      } else {
        _warningMessage = null;
      }
    });
  }

  double get _currentTotalCost {
    double total = 0.0;
    for (final item in _menuItems) {
      final qty = _quantities[item.id] ?? 0;
      total += item.cost * qty;
    }
    return total;
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _incrementItem(FoodItem item) {
    if (item.id == null) return;
    final projected = _currentTotalCost + item.cost;
    if (projected > _activeTargetCost + 0.001) {
      setState(() {
        _warningMessage =
        'Adding "${item.name}" exceeds \$${_activeTargetCost.toStringAsFixed(2)} target!';
      });
      return;
    }
    setState(() {
      _warningMessage = null;
      _quantities[item.id!] = (_quantities[item.id!] ?? 0) + 1;
    });
  }

  void _decrementItem(FoodItem item) {
    if (item.id == null) return;
    final current = _quantities[item.id!] ?? 0;
    if (current <= 0) return;
    setState(() {
      if (current == 1) {
        _quantities.remove(item.id!);
      } else {
        _quantities[item.id!] = current - 1;
      }
      if (_currentTotalCost <= _activeTargetCost + 0.001) {
        _warningMessage = null;
      }
    });
  }

  Future<void> _saveChanges() async {
    final total = _currentTotalCost;
    if (_activeTargetCost <= 0) {
      setState(() => _warningMessage = 'Target cost must be greater than \$0.00.');
      return;
    }
    if (_quantities.isEmpty) {
      setState(() => _warningMessage = 'Select at least one item.');
      return;
    }
    if (total > _activeTargetCost + 0.001) {
      setState(() => _warningMessage = 'Total exceeds target cost.');
      return;
    }

    final List<FoodItem> updatedItems = [];
    for (final item in _menuItems) {
      final qty = _quantities[item.id] ?? 0;
      for (int i = 0; i < qty; i++) {
        updatedItems.add(item);
      }
    }

    final OrderPlan updatedPlan = OrderPlan(
      id: widget.plan.id,
      date: _formatDate(_selectedDate),
      targetCost: _activeTargetCost,
      totalCost: total,
      items: updatedItems,
    );

    await DatabaseHelper.instance.updateOrderPlan(updatedPlan);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Order Plan'),
      content: SizedBox(
        width: double.maxFinite,
        height: 430,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _targetCostController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Target (\$)',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      errorText: _targetInputError,
                    ),
                    onChanged: (val) {
                      final p = double.tryParse(val.trim());
                      setState(() {
                        _targetInputError =
                        (p == null || p <= 0) ? '> \$0.00' : null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: _canSetNewTarget ? _applyTargetCost : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  child: const Text('Set'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 15),
                  label: Text(_formatDate(_selectedDate)),
                ),
                Text(
                  '\$${_currentTotalCost.toStringAsFixed(2)} / \$${_activeTargetCost.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.espressoBrown,
                  ),
                ),
              ],
            ),
            if (_warningMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _warningMessage!,
                  style: const TextStyle(
                    color: AppTheme.mapleRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const Divider(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  final qty = _quantities[item.id] ?? 0;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('\$${item.cost.toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              size: 20),
                          onPressed:
                          qty > 0 ? () => _decrementItem(item) : null,
                        ),
                        Text('$qty',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle,
                              size: 20, color: AppTheme.mapleRed),
                          onPressed: () => _incrementItem(item),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}