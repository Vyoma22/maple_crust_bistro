import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/food_item.dart';
import '../theme/app_theme.dart';

/// Screen for adding, updating, and deleting food items in the local database.
class ManageMenuTab extends StatefulWidget {
  final VoidCallback onMenuChanged;

  const ManageMenuTab({super.key, required this.onMenuChanged});

  @override
  State<ManageMenuTab> createState() => _ManageMenuTabState();
}

class _ManageMenuTabState extends State<ManageMenuTab> {
  List<FoodItem> _foodItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFoodItems();
  }

  /// Loads all food items from SQLite.
  Future<void> _loadFoodItems() async {
    final items = await DatabaseHelper.instance.getAllFoodItems();
    if (!mounted) return;
    setState(() {
      _foodItems = items;
      _isLoading = false;
    });
  }

  /// Opens a dialog to either create a new FoodItem or edit an existing one.
  Future<void> _showFoodItemDialog({FoodItem? existingItem}) async {
    final bool isEditing = existingItem != null;
    final TextEditingController nameController =
    TextEditingController(text: existingItem?.name ?? '');
    final TextEditingController costController = TextEditingController(
      text: existingItem != null ? existingItem.cost.toStringAsFixed(2) : '',
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Update Food Item' : 'Add New Food Item'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Food Item Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a food item name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: costController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Cost (\$)',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value?.trim() ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid cost greater than \$0.00';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final String cleanName = nameController.text.trim();
                final double cleanCost = double.parse(
                  double.parse(costController.text.trim()).toStringAsFixed(2),
                );

                if (isEditing) {
                  await DatabaseHelper.instance.updateFoodItem(
                    existingItem.copyWith(name: cleanName, cost: cleanCost),
                  );
                } else {
                  await DatabaseHelper.instance.insertFoodItem(
                    FoodItem(name: cleanName, cost: cleanCost),
                  );
                }

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      await _loadFoodItems();
      widget.onMenuChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Food item updated!' : 'New food item added to menu!',
            ),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  /// Prompts for confirmation and deletes a FoodItem from SQLite.
  Future<void> _confirmDeleteFoodItem(FoodItem item) async {
    if (item.id == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Food Item'),
          content: Text(
            'Are you sure you want to remove "${item.name}" (\$${item.cost.toStringAsFixed(2)}) from the menu?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.mapleRed,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteFoodItem(item.id!);
      await _loadFoodItems();
      widget.onMenuChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Deleted "${item.name}" from menu.'),
            backgroundColor: AppTheme.mapleRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Manage Menu (${_foodItems.length} Items)',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.espressoBrown,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showFoodItemDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
              itemCount: _foodItems.length,
              itemBuilder: (context, index) {
                final FoodItem item = _foodItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.espressoBrown,
                      ),
                    ),
                    subtitle: Text(
                      '\$${item.cost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.mapleRed,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit item',
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: AppTheme.espressoBrown,
                          ),
                          onPressed: () =>
                              _showFoodItemDialog(existingItem: item),
                        ),
                        IconButton(
                          tooltip: 'Delete item',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppTheme.mapleRed,
                          ),
                          onPressed: () => _confirmDeleteFoodItem(item),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}