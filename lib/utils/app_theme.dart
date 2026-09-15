import 'package:flutter/material.dart';

class AppTheme {
  static const Color maroon = Color(0xFF7B1E2C);
  static const Color gold = Color(0xFFC5A572);
  static const Color cream = Color(0xFFF7F3EC);
  static const Color ink = Color(0xFF1F1A17);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: maroon,
      primary: maroon,
      secondary: gold,
      surface: cream,
      brightness: Brightness.light,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: maroon,
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: maroon,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
