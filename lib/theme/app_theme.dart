import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Medical theme system for DiaCare - professional healthcare appearance
class MedicalTheme {
  // Medical Primary Colors - Using #222831 as requested
  static const Color primaryMedicalBlue = Color(0xFF222831);
  static const Color lightMedicalBlue = Color(0xFF393E46);
  static const Color darkMedicalBlue = Color(0xFF1A1D23);
  
  // Background Colors - Clean medical appearance
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color surfaceGray = Color(0xFFF8F9FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  
  // Dark Theme Colors - Softer dark theme with better contrast
  static const Color darkBackground = Color(0xFF000000);     // Pure black background
  static const Color darkSurface = Color(0xFF121212);        // Slightly elevated black
  static const Color darkCard = Color(0xFF1E1E1E);           // Soft dark gray for cards
  
  // Medical Icon Colors - Proper medical color coding with dark mode variants
  static const Color glucoseGreen = Color(0xFF4CAF50);      // Green for glucose (good/normal)
  static const Color medicationOrange = Color(0xFFFF9800);  // Orange for medications
  static const Color activityPurple = Color(0xFF9C27B0);    // Purple for activity
  static const Color aiGold = Color(0xFFFFB300);            // Gold for AI insights
  static const Color bloodPressureRed = Color(0xFFF44336);  // Red for blood pressure
  static const Color nutritionBlue = Color(0xFF2196F3);     // Blue for nutrition
  static const Color heartRed = Color(0xFFE91E63);          // Pink-red for heart/health
  static const Color hydrationCyan = Color(0xFF00BCD4);     // Softer cyan for hydration
  
  // Dark Mode Softer Variants
  static const Color darkHydrationCyan = Color(0xFF4DD0E1); // Softer cyan for dark mode
  static const Color darkActivityPurple = Color(0xFFBA68C8); // Softer purple for dark mode
  
  // Status Colors - Medical appropriate
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningAmber = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color infoBlue = Color(0xFF2196F3);
  
  /// Get theme-appropriate hydration color
  static Color getHydrationColor(bool isDarkMode) {
    return isDarkMode ? darkHydrationCyan : hydrationCyan;
  }
  
  /// Get theme-appropriate activity color
  static Color getActivityColor(bool isDarkMode) {
    return isDarkMode ? darkActivityPurple : activityPurple;
  }
}

class AppTheme {
  static ThemeData lightTheme(ColorScheme? dynamicScheme) {
    // Simple light theme with medical colors
    final scheme = const ColorScheme.light(
      primary: MedicalTheme.primaryMedicalBlue,
      secondary: MedicalTheme.lightMedicalBlue,
      surface: MedicalTheme.backgroundWhite,
      onSurface: Colors.black87,
      onSurfaceVariant: Colors.black54,
      outline: Colors.black12,
      outlineVariant: Colors.black12,
      // Override Material 3 container colors to prevent green borders
      primaryContainer: MedicalTheme.primaryMedicalBlue,
      onPrimaryContainer: Colors.white,
      secondaryContainer: MedicalTheme.lightMedicalBlue,
      onSecondaryContainer: Colors.white,
      surfaceContainerHighest: MedicalTheme.surfaceGray,
    );

    return ThemeData(
      useMaterial3: false, // Disable Material 3 to avoid unwanted default colors
      colorScheme: scheme,
      scaffoldBackgroundColor: MedicalTheme.backgroundWhite,
      cardColor: MedicalTheme.cardWhite,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: MedicalTheme.cardWhite,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MedicalTheme.primaryMedicalBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: MedicalTheme.primaryMedicalBlue,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MedicalTheme.primaryMedicalBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      // Override any potential Material 3 colors
      focusColor: MedicalTheme.primaryMedicalBlue.withValues(alpha: 0.1),
      hoverColor: MedicalTheme.primaryMedicalBlue.withValues(alpha: 0.05),
      splashColor: MedicalTheme.primaryMedicalBlue.withValues(alpha: 0.1),
      highlightColor: MedicalTheme.primaryMedicalBlue.withValues(alpha: 0.1),
      // Disable Material 3 surface tints completely
      extensions: const [],
    );
  }

  static ThemeData darkTheme(ColorScheme? dynamicScheme) {
    // Simple dark theme with medical colors
    final scheme = const ColorScheme.dark(
      primary: MedicalTheme.primaryMedicalBlue,
      secondary: MedicalTheme.lightMedicalBlue,
      surface: MedicalTheme.darkSurface,
      onSurface: Colors.white,
      onSurfaceVariant: Colors.white70,
      outline: Colors.white24,
      outlineVariant: Colors.white12,
      // Override Material 3 container colors to prevent green borders
      primaryContainer: MedicalTheme.lightMedicalBlue,
      onPrimaryContainer: Colors.white,
      secondaryContainer: MedicalTheme.primaryMedicalBlue,
      onSecondaryContainer: Colors.white,
      surfaceContainerHighest: MedicalTheme.darkCard,
    );

    return ThemeData(
      useMaterial3: false, // Disable Material 3 to avoid unwanted default colors
      colorScheme: scheme,
      scaffoldBackgroundColor: MedicalTheme.darkBackground,
      cardColor: MedicalTheme.darkCard,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: MedicalTheme.darkCard,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MedicalTheme.lightMedicalBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: MedicalTheme.lightMedicalBlue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      // Simple text theme for dark mode
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.white),
        headlineMedium: TextStyle(color: Colors.white),
        headlineSmall: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.white70),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MedicalTheme.lightMedicalBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
      ),
      // Override any potential Material 3 colors
      focusColor: MedicalTheme.lightMedicalBlue.withValues(alpha: 0.1),
      hoverColor: MedicalTheme.lightMedicalBlue.withValues(alpha: 0.05),
      splashColor: MedicalTheme.lightMedicalBlue.withValues(alpha: 0.1),
      highlightColor: MedicalTheme.lightMedicalBlue.withValues(alpha: 0.1),
      // Disable Material 3 surface tints completely
      extensions: const [],
    );
  }
}
