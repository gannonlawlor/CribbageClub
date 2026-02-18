import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Colors
  static const Color feltGreen = Color(0xFF2E7D32);
  static const Color feltGreenDark = Color(0xFF1B5E20);
  static const Color feltGreenLight = Color(0xFF4CAF50);
  static const Color cardWhite = Color(0xFFFFFDE7);
  static const Color cardBorder = Color(0xFF424242);
  static const Color suitRed = Color(0xFFC62828);
  static const Color suitBlack = Color(0xFF212121);
  static const Color goldAccent = Color(0xFFFFD54F);
  static const Color selectedHighlight = Color(0x4DFFEB3B);

  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: feltGreen,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: feltGreenDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: feltGreenDark,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: feltGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        cardTheme: const CardThemeData(
          color: cardWhite,
          elevation: 2,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      );
}
