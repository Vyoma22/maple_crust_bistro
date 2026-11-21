import 'dart:convert';
import 'food_item.dart';

/// Data model representing a user's saved daily order plan.
class OrderPlan {
  final int? id;
  final String date; // Stored in ISO-8601 YYYY-MM-DD format for accurate sorting
  final double targetCost;
  final double totalCost;
  final List<FoodItem> items;

  const OrderPlan({
    this.id,
    required this.date,
    required this.targetCost,
    required this.totalCost,
    required this.items,
  });

  /// Converts an OrderPlan instance into a SQLite-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'target_cost': targetCost,
      'total_cost': totalCost,
      'items_json': jsonEncode(items.map((item) => item.toMap()).toList()),
    };
  }

  /// Creates an OrderPlan instance from a SQLite row Map.
  factory OrderPlan.fromMap(Map<String, dynamic> map) {
    final List<dynamic> decodedList =
    jsonDecode(map['items_json'] as String) as List<dynamic>;
    final List<FoodItem> parsedItems = decodedList
        .map((itemMap) => FoodItem.fromMap(itemMap as Map<String, dynamic>))
        .toList();

    return OrderPlan(
      id: map['id'] as int?,
      date: map['date'] as String,
      targetCost: (map['target_cost'] as num).toDouble(),
      totalCost: (map['total_cost'] as num).toDouble(),
      items: parsedItems,
    );
  }
}