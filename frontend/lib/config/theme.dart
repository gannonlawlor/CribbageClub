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

  // Felt gradient (top→bottom, 3-stop)
  static const LinearGradient feltGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1B5E20), // dark top
      Color(0xFF2E7D32), // mid green
      Color(0xFF1B5E20), // dark bottom
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Card aspect ratio (standard playing card 2.5:3.5)
  static const double cardAspectRatio = 2.5 / 3.5;

  // Cribbage board colors
  static const Color boardBrown = Color(0xFF5D4037);
  static const Color boardBrownLight = Color(0xFF795548);
  static const Color boardHole = Color(0xFF3E2723);
  static const Color pegGold = Color(0xFFFFD54F);
  static const Color pegWhite = Color(0xFFEEEEEE);

  // Animation durations
  static const Duration cardFlipDuration = Duration(milliseconds: 400);
  static const Duration cardDealDuration = Duration(milliseconds: 300);
  static const Duration cardPlayDuration = Duration(milliseconds: 250);
  static const Duration scalBounceDuration = Duration(milliseconds: 200);
  static const Duration cribStaggerDelay = Duration(milliseconds: 100);
  static const Duration pegMovePerHole = Duration(milliseconds: 50);
  static const Duration scorePopupDuration = Duration(milliseconds: 1800);
  static const Duration stageTransitionDuration = Duration(milliseconds: 400);

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
