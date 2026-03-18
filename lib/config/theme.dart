import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AppTheme {
  // ============ COLOR REDIRECTS FOR COMPATIBILITY ============
  static const Color primary = AppColors.primary;
  static const Color secondary = AppColors.secondary;
  static const Color white = AppColors.white;
  static const Color black = AppColors.black;
  static const Color background = AppColors.background;
  static const Color error = AppColors.error;
  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;
  static const Color grey600 = Color(0xFF495057); // Keep some specific greys if needed or map them
  static const Color grey800 = Color(0xFF0A0E1A);
  static const Color accent = AppColors.primary; // Falling back to primary if accent is missing

  // ============ LIGHT THEME ============
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.white,

      // ============ COLOR SCHEME ============
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        background: AppColors.white,
        onBackground: AppColors.black,
        surface: AppColors.background,
        error: AppColors.error,
      ),

      // ============ APP BAR THEME ============
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // ============ BUTTON THEMES ============
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),

      // ============ INPUT DECORATION THEME ============
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: AppColors.textSecondary),
        labelStyle: TextStyle(color: AppColors.textPrimary),
      ),

      // ============ CARD THEME ============
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
      ),
    );
  }

  // ============ DARK THEME ============
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkBackground,

      // ============ COLOR SCHEME ============
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        background: AppColors.darkBackground,
        surface: AppColors.darkPrimary,
        error: AppColors.error,
      ),

      // ============ APP BAR THEME ============
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      inputDecorationTheme: const InputDecorationTheme(
        fillColor: Color(0xFF2C2C2C),
        hintStyle: TextStyle(color: AppColors.white),
        labelStyle: TextStyle(color: AppColors.white),
      ),
    );
  }
}