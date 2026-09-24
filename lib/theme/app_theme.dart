import 'package:flutter/material.dart';

class AppTheme {
  // Main De-Fame purple used throughout the app.
  static const Color primaryPurple = Color(0xFF9B30FF);

  // Brighter purple that can be used for glow-style accents.
  static const Color accentPurple = Color(0xFFC44DFF);

  // Main dark background color.
  static const Color darkBackground = Color(0xFF111111);

  // Slightly lighter dark color for cards and other surfaces.
  static const Color darkSurface = Color(0xFF1C1C1F);

  // Main light background color.
  static const Color lightBackground = Color(0xFFF7F4FA);

  // Light card/surface color.
  static const Color lightSurface = Colors.white;

  // -----------------------------
  // LIGHT THEME
  // -----------------------------
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // This tells Flutter this is a light theme.
      brightness: Brightness.light,

      // Main color system for light mode.
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPurple,
        brightness: Brightness.light,
      ),

      // Main screen background color.
      scaffoldBackgroundColor: lightBackground,

      // Default app bar styling.
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      // Default card styling.
      cardTheme: const CardThemeData(
        color: lightSurface,
        elevation: 1,
        margin: EdgeInsets.all(8),
      ),

      // Default filled button styling.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // -----------------------------
  // DARK THEME
  // -----------------------------
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,

      // This tells Flutter this is a dark theme.
      brightness: Brightness.dark,

      // Main color system for dark mode.
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPurple,
        brightness: Brightness.dark,
      ),

      // Main screen background color.
      scaffoldBackgroundColor: darkBackground,

      // Default app bar styling.
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      // Default card styling.
      cardTheme: const CardThemeData(
        color: darkSurface,
        elevation: 1,
        margin: EdgeInsets.all(8),
      ),

      // Default filled button styling.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}