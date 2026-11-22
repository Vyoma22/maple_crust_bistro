import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'order_builder_tab.dart';

/// Main navigation shell displaying the restaurant branding and tab views.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

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

  /// Returns the view for the currently selected bottom navigation tab.
  Widget _buildCurrentTab() {
    switch (_selectedIndex) {
      case 0:
        return const OrderBuilderTab();
      case 1:
        return const Center(
          child: Text(
            'Order Plans & Date Search',
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