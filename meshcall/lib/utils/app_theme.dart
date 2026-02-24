import 'package:flutter/material.dart';

/// App Theme & Constants
class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color secondaryColor = Color(0xFF3DD598);
  static const Color accentColor = Color(0xFFFF6584);
  static const Color darkBg = Color(0xFF1A1A2E);
  static const Color darkSurface = Color(0xFF16213E);
  static const Color darkCard = Color(0xFF0F3460);
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color textLight = Color(0xFFE8E8E8);
  static const Color textDark = Color(0xFF2C2C2C);
  static const Color onlineGreen = Color(0xFF4CAF50);
  static const Color offlineGrey = Color(0xFF9E9E9E);
  static const Color callGreen = Color(0xFF4CAF50);
  static const Color callRed = Color(0xFFE53935);
  static const Color meshBlue = Color(0xFF2196F3);

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBg,
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          secondary: secondaryColor,
          surface: darkSurface,
          error: callRed,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: darkSurface,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: textLight,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: darkCard,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: darkSurface,
          selectedItemColor: primaryColor,
          unselectedItemColor: offlineGrey,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: textLight.withOpacity(0.5)),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: textLight,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: textLight,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: textLight, fontSize: 16),
          bodyMedium: TextStyle(color: textLight, fontSize: 14),
          bodySmall: TextStyle(
            color: offlineGrey,
            fontSize: 12,
          ),
        ),
      );
}
