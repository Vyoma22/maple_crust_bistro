import 'package:flutter/material.dart';

/// Centralized theme configuration for Maple Crust Bistro.
class AppTheme {
  // Brand Color Palette
  static const Color mapleRed = Color(0xFFB71C1C);
  static const Color warmCream = Color(0xFFFFF8F0);
  static const Color espressoBrown = Color(0xFF3E2723);
  static const Color goldenCrust = Color(0xFFD97706);
  static const Color softSand = Color(0xFFF3E5D8);

  /// Builds the main Material 3 ThemeData for the application.
  static ThemeData get lightTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: mapleRed,
      primary: mapleRed,
      secondary: goldenCrust,
      surface: warmCream,
      onSurface: espressoBrown,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: warmCream,
      appBarTheme: const AppBarTheme(
        backgroundColor: mapleRed,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: softSand, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: mapleRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: softSand,
        indicatorColor: mapleRed.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontWeight: FontWeight.w600,
            color: espressoBrown,
          ),
        ),
      ),
    );
  }
}