import 'package:flutter/material.dart';

class AppTheme {
  static final Color _seedColor = Colors.redAccent;

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    return ThemeData.from(colorScheme: colorScheme).copyWith(
      cardTheme: CardThemeData( // Corrected from CardTheme
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
    return ThemeData.from(colorScheme: colorScheme).copyWith(
      cardTheme: CardThemeData( // Corrected from CardTheme
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
