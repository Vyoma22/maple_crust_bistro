import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/food_item.dart';

/// Singleton helper managing local SQLite database creation, seeding, and queries.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  static const String _dbName = 'maple_crust_bistro.db';
  static const int _dbVersion = 1;

  static const String tableFoodItems = 'food_items';
  static const String tableOrderPlans = 'order_plans';

  /// Returns the existing database instance or initializes it on first access.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Opens the SQLite database file and triggers table creation on initial install.
  Future<Database> _initDatabase() async {
    final String dbPath = await getDatabasesPath();
    final String path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  /// Creates database tables and seeds initial menu items upon first install.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableFoodItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        cost REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableOrderPlans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        target_cost REAL NOT NULL,
        total_cost REAL NOT NULL,
        items_json TEXT NOT NULL
      )
    ''');

    await _seedInitialFoodItems(db);
  }

  /// Inserts 22 Maple Crust Bistro food items and prices into the database.
  Future<void> _seedInitialFoodItems(Database db) async {
    final List<FoodItem> initialMenu = [
      const FoodItem(name: 'Maple Glazed Croissant', cost: 3.75),
      const FoodItem(name: 'Roasted Turkey & Brie Baguette', cost: 11.50),
      const FoodItem(name: 'Smoked Salmon & Herb Bagel', cost: 10.25),
      const FoodItem(name: 'Classic Peameal Bacon Brioche', cost: 9.75),
      const FoodItem(name: 'Artisanal Grilled Cheese & Tomato', cost: 8.50),
      const FoodItem(name: 'Harvest Butternut Squash Soup', cost: 6.25),
      const FoodItem(name: 'Creamy Wild Mushroom Soup', cost: 6.50),
      const FoodItem(name: 'Country Chicken Pot Pie', cost: 12.00),
      const FoodItem(name: 'Spinach & Feta Puff Pastry', cost: 5.25),
      const FoodItem(name: 'Apple Cinnamon Turnover', cost: 4.15),
      const FoodItem(name: 'Wild Blueberry Oat Muffin', cost: 3.50),
      const FoodItem(name: 'Double Chocolate Espresso Brownie', cost: 4.25),
      const FoodItem(name: 'Butter Tart Square', cost: 3.95),
      const FoodItem(name: 'Freshly Brewed Dark Roast Coffee', cost: 2.50),
      const FoodItem(name: 'Maple Oat Milk Latte', cost: 5.25),
      const FoodItem(name: 'Caramel Macchiato', cost: 5.00),
      const FoodItem(name: 'Spiced Chai Tea Latte', cost: 4.75),
      const FoodItem(name: 'London Fog Earl Grey Latte', cost: 4.65),
      const FoodItem(name: 'Iced Maple Cold Brew', cost: 4.85),
      const FoodItem(name: 'Fresh Squeezed Orange Juice', cost: 3.90),
      const FoodItem(name: 'Mixed Berry Yogurt Parfait', cost: 5.75),
      const FoodItem(name: 'Avocado & Poached Egg Sourdough', cost: 10.75),
    ];

    final Batch batch = db.batch();
    for (final FoodItem item in initialMenu) {
      batch.insert(tableFoodItems, item.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// Retrieves all food items from the database ordered alphabetically by name.
  Future<List<FoodItem>> getAllFoodItems() async {
    final db = await database;
    final maps = await db.query(
      tableFoodItems,
      orderBy: 'name ASC',
    );
    return maps.map((map) => FoodItem.fromMap(map)).toList();
  }
}