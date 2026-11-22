import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/order_plan.dart';
import '../theme/app_theme.dart';

/// Screen for querying order plans by a specific date and viewing
/// all saved order plans ordered by date descending.
class OrderPlansTab extends StatefulWidget {
  const OrderPlansTab({super.key});

  @override
  State<OrderPlansTab> createState() => _OrderPlansTabState();
}

class _OrderPlansTabState extends State<OrderPlansTab> {
  List<OrderPlan> _allPlans = [];
  bool _isLoading = true;

  DateTime? _queryDate;
  List<OrderPlan> _queryResults = [];
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadAllOrderPlans();
  }

  /// Loads all saved order plans from SQLite ordered by date descending.
  Future<void> _loadAllOrderPlans() async {
    final plans = await DatabaseHelper.instance.getAllOrderPlansDescending();
    if (!mounted) return;
    setState(() {
      _allPlans = plans;
      _isLoading = false;
    });
  }

  /// Formats a DateTime object as YYYY-MM-DD.
  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Opens a date picker and queries SQLite for order plans on that date.
  Future<void> _pickAndQueryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _queryDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;

    final String formattedDate = _formatDate(picked);
    final List<OrderPlan> matches =
    await DatabaseHelper.instance.getOrderPlansByDate(formattedDate);

    if (!mounted) return;
    setState(() {
      _queryDate = picked;
      _queryResults = matches;
      _hasSearched = true;
    });
  }

  /// Resets the active date query filter.
  void _clearQuery() {
    setState(() {
      _queryDate = null;
      _queryResults = [];
      _hasSearched = false;
    });
  }

  /// Builds a reusable card widget displaying a single saved OrderPlan.
  Widget _buildOrderPlanCard(OrderPlan plan, {bool isQueryMatch = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: isQueryMatch ? AppTheme.softSand : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.event_available,
                      color: AppTheme.mapleRed,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      plan.date,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.espressoBrown,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.mapleRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Total: \$${plan.totalCost.toStringAsFixed(2)} / \$${plan.targetCost.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Text(
              'Items (${plan.items.length}):',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.espressoBrown,
              ),
            ),
            const SizedBox(height: 4),
            ...plan.items.map(
                  (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '• ${item.name}',
                        style: const TextStyle(fontSize: 13.5),
                      ),
                    ),
                    Text(
                      '\$${item.cost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.espressoBrown,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the date query card and displays either found plans or a not-found notice.
  Widget _buildQuerySection() {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Query Order Plan by Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.espressoBrown,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickAndQueryDate,
                    icon: const Icon(Icons.search),
                    label: Text(
                      _queryDate == null
                          ? 'Select Date to Search'
                          : 'Searched: ${_formatDate(_queryDate!)}',
                    ),
                  ),
                ),
                if (_hasSearched) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Clear search',
                    onPressed: _clearQuery,
                    icon: const Icon(Icons.close, color: AppTheme.mapleRed),
                  ),
                ],
              ],
            ),
            if (_hasSearched) ...[
              const SizedBox(height: 12),
              if (_queryResults.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.goldenCrust),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.goldenCrust,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No order plan found in the database for ${_formatDate(_queryDate!)}.',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.espressoBrown,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Found ${_queryResults.length} order plan(s) for ${_formatDate(_queryDate!)}:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ..._queryResults.map(
                          (plan) => _buildOrderPlanCard(plan, isQueryMatch: true),
                    ),
                  ],
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

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _buildQuerySection(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'All Saved Order Plans (${_allPlans.length}) — Newest First',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.espressoBrown,
            ),
          ),
        ),
        if (_allPlans.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No order plans saved yet.\nCreate one in the Order Builder tab!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children:
              _allPlans.map((plan) => _buildOrderPlanCard(plan)).toList(),
            ),
          ),
      ],
    );
  }
}