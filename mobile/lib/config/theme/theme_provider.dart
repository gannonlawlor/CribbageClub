import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_colors.dart';

enum AppThemeMode { classicLight, classicDark, system }

final themeProvider = StateProvider<AppThemeMode>((_) => AppThemeMode.classicLight);

/// Resolve system mode to concrete light/dark based on platform brightness.
AppThemeMode resolveThemeMode(AppThemeMode mode, Brightness platformBrightness) {
  if (mode == AppThemeMode.system) {
    return platformBrightness == Brightness.dark
        ? AppThemeMode.classicDark
        : AppThemeMode.classicLight;
  }
  return mode;
}

ThemeData buildThemeData(AppThemeMode mode) {
  final colors = switch (mode) {
    AppThemeMode.classicLight => AppColors.classicLight,
    AppThemeMode.classicDark => AppColors.classicDark,
    AppThemeMode.system => AppColors.classicLight, // fallback, should be resolved first
  };

  final brightness =
      mode == AppThemeMode.classicLight ? Brightness.light : Brightness.dark;

  return ThemeData(
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: colors.accent,
      brightness: brightness,
    ),
    scaffoldBackgroundColor: colors.scaffoldBg,
    appBarTheme: AppBarTheme(
      backgroundColor: colors.scaffoldBg,
      foregroundColor: colors.textPrimary,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.buttonPrimary,
        foregroundColor: colors.accentOnSurface,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.textPrimary,
        side: BorderSide(color: colors.textDisabled),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.accent,
      ),
    ),
    cardTheme: CardThemeData(color: colors.cardFace, elevation: 2),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surfacePrimary,
      titleTextStyle: TextStyle(
        color: colors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: colors.textSecondary,
        fontSize: 14,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceDim,
      hintStyle: TextStyle(color: colors.textDisabled),
      labelStyle: TextStyle(color: colors.textSecondary),
      border: const OutlineInputBorder(),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        color: colors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(color: colors.textPrimary),
      bodyMedium: TextStyle(color: colors.textSecondary),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.surfacePrimary,
      contentTextStyle: TextStyle(color: colors.textPrimary),
    ),
    dividerColor: colors.divider,
    extensions: [colors],
  );
}
