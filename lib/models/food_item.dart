/// Data model representing a menu item and its price.
class FoodItem {
  final int? id;
  final String name;
  final double cost;

  const FoodItem({
    this.id,
    required this.name,
    required this.cost,
  });

  /// Converts a FoodItem instance into a SQLite-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cost': cost,
    };
  }

  /// Creates a FoodItem instance from a SQLite row Map.
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      cost: (map['cost'] as num).toDouble(),
    );
  }

  /// Returns a copy of this FoodItem with updated fields.
  FoodItem copyWith({
    int? id,
    String? name,
    double? cost,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      cost: cost ?? this.cost,
    );
  }
}