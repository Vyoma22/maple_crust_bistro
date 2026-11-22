import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'order_builder_tab.dart';
import 'order_plans_tab.dart';

/// Main navigation shell displaying the restaurant branding and tab views.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  // Incremented when switching to Order Plans so newly saved plans load immediately
  int _orderPlansRefreshKey = 0;

  /// Updates the active tab index and refreshes Order Plans when opened.
  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 1) {
        _orderPlansRefreshKey++;
      }
    });
  }

  /// Builds the branded header banner showing the restaurant logo and tagline.
  Widget _buildBrandHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppTheme.mapleRed,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bakery_dining,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maple Crust Bistro',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.espressoBrown,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Fresh Artisanal Sandwiches, Soups & Coffee',
                  style: TextStyle(
                    fontSize: 12.5,
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
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                // Kept alive in memory so target cost, date, and selections persist
                const OrderBuilderTab(),
                // Rebuilds with fresh SQLite data whenever opened
                OrderPlansTab(key: ValueKey(_orderPlansRefreshKey)),
                const Center(
                  child: Text(
                    'Manage Menu Items',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
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