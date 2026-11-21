import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/food_item.dart';
import '../theme/app_theme.dart';

/// Main navigation shell displaying the restaurant branding and tab views.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  List<FoodItem> _foodItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFoodItems();
  }

  /// Fetches all seeded/stored food items from the local SQLite database.
  Future<void> _loadFoodItems() async {
    final List<FoodItem> items =
    await DatabaseHelper.instance.getAllFoodItems();
    if (!mounted) return;
    setState(() {
      _foodItems = items;
      _isLoading = false;
    });
  }

  /// Updates the active tab index when the user taps a navigation destination.
  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Builds the branded header banner showing the restaurant logo and tagline.
  Widget _buildBrandHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.softSand,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.mapleRed.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.mapleRed,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bakery_dining,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maple Crust Bistro',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.espressoBrown,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Fresh Artisanal Sandwiches, Soups & Coffee',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.espressoBrown,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Displays the seeded menu items and costs loaded from SQLite.
  Widget _buildMenuPreviewTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_foodItems.isEmpty) {
      return const Center(
        child: Text('No menu items found in the database.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(
            'Bistro Menu (${_foodItems.length} Seeded Items)',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.espressoBrown,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: _foodItems.length,
            itemBuilder: (context, index) {
              final FoodItem item = _foodItems[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.softSand,
                    child: const Icon(
                      Icons.restaurant,
                      color: AppTheme.mapleRed,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.espressoBrown,
                    ),
                  ),
                  trailing: Text(
                    '\$${item.cost.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.mapleRed,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Returns the view for the currently selected bottom navigation tab.
  Widget _buildCurrentTab() {
    switch (_selectedIndex) {
      case 0:
        return _buildMenuPreviewTab();
      case 1:
        return const Center(
          child: Text(
            'Order Plans & Date Search)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        );
      case 2:
      default:
        return const Center(
          child: Text(
            'Manage Menu Items',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maple Crust Bistro'),
      ),
      body: Column(
        children: [
          _buildBrandHeader(),
          Expanded(
            child: _buildCurrentTab(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Order Builder',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Order Plans',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Manage Menu',
          ),
        ],
      ),
    );
  }
}