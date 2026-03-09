import 'package:flutter/material.dart';
import 'constants.dart';

class AppTheme {
  // ============ COLOR PALETTE ============
  static const Color primary = Color(0xFF1F4E78); // Dark Blue
  static const Color primaryLight = Color(0xFF2E75B6); // Light Blue
  static const Color primaryLighter = Color(0xFFD5E8F0); // Lighter Blue
  static const Color secondary = Color(0xFF70AD47); // Green
  static const Color accent = Color(0xFFFFC000); // Gold
  static const Color error = Color(0xFFC00000); // Red
  static const Color warning = Color(0xFFFF6B00); // Orange
  static const Color success = Color(0xFF70AD47); // Green
  static const Color info = Color(0xFF2E75B6); // Blue

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFF8F9FA);
  static const Color grey100 = Color(0xFFF0F2F5);
  static const Color grey200 = Color(0xFFE0E6ED);
  static const Color grey300 = Color(0xFFCED4DA);
  static const Color grey400 = Color(0xFFADB5BD);
  static const Color grey500 = Color(0xFF868E96);
  static const Color grey600 = Color(0xFF495057);
  static const Color grey700 = Color(0xFF373F47);
  static const Color grey800 = Color(0xFF212529);

  // ============ LIGHT THEME ============
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: white,

      // ============ COLOR SCHEME ============
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryLight,
        secondary: secondary,
        tertiary: accent,
        error: error,
        surface: white,
        outline: grey300,
      ),

      // ============ APP BAR THEME ============
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: white,
          fontSize: AppFontSize.xl,
          fontWeight: FontWeight.bold,
        ),
      ),

      // ============ TEXT THEMES ============
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: AppFontSize.h1,
          fontWeight: FontWeight.bold,
          color: black,
        ),
        displayMedium: TextStyle(
          fontSize: AppFontSize.h2,
          fontWeight: FontWeight.bold,
          color: black,
        ),
        displaySmall: TextStyle(
          fontSize: AppFontSize.h3,
          fontWeight: FontWeight.bold,
          color: black,
        ),
        headlineMedium: TextStyle(
          fontSize: AppFontSize.h4,
          fontWeight: FontWeight.bold,
          color: black,
        ),
        headlineSmall: TextStyle(
          fontSize: AppFontSize.h5,
          fontWeight: FontWeight.bold,
          color: black,
        ),
        titleLarge: TextStyle(
          fontSize: AppFontSize.h6,
          fontWeight: FontWeight.bold,
          color: black,
        ),
        titleMedium: TextStyle(
          fontSize: AppFontSize.xl,
          fontWeight: FontWeight.w600,
          color: black,
        ),
        titleSmall: TextStyle(
          fontSize: AppFontSize.lg,
          fontWeight: FontWeight.w600,
          color: grey600,
        ),
        bodyLarge: TextStyle(
          fontSize: AppFontSize.lg,
          fontWeight: FontWeight.normal,
          color: black,
        ),
        bodyMedium: TextStyle(
          fontSize: AppFontSize.base,
          fontWeight: FontWeight.normal,
          color: grey600,
        ),
        bodySmall: TextStyle(
          fontSize: AppFontSize.sm,
          fontWeight: FontWeight.normal,
          color: grey500,
        ),
        labelLarge: TextStyle(
          fontSize: AppFontSize.base,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        labelMedium: TextStyle(
          fontSize: AppFontSize.sm,
          fontWeight: FontWeight.w600,
          color: grey600,
        ),
        labelSmall: TextStyle(
          fontSize: AppFontSize.xs,
          fontWeight: FontWeight.w600,
          color: grey500,
        ),
      ),

      // ============ BUTTON THEMES ============
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(
            vertical: AppPadding.md,
            horizontal: AppPadding.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          elevation: 2,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(
            vertical: AppPadding.md,
            horizontal: AppPadding.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
            vertical: AppPadding.sm,
            horizontal: AppPadding.md,
          ),
        ),
      ),

      // ============ INPUT DECORATION THEME ============
      inputDecorationTheme: InputDecorationTheme(
        fillColor: grey50,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: AppPadding.md,
          horizontal: AppPadding.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: grey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(
          color: grey600,
          fontSize: AppFontSize.base,
        ),
        hintStyle: const TextStyle(
          color: grey400,
          fontSize: AppFontSize.base,
        ),
      ),

      // ============ CARD THEME (Material 3) ============
      cardTheme: CardThemeData(
        color: white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: grey200),
        ),
      ),

      // ============ DIALOG THEME (Material 3) ============
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        backgroundColor: white,
      ),

      // ============ BOTTOM SHEET THEME ============
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.xl),
            topRight: Radius.circular(AppRadius.xl),
          ),
        ),
        backgroundColor: white,
      ),

      // ============ DIVIDER THEME ============
      dividerTheme: const DividerThemeData(
        color: grey200,
        thickness: 1,
        space: AppPadding.md,
      ),
    );
  }

  // ============ DARK THEME ============
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryLight,
      scaffoldBackgroundColor: grey800,

      // ============ COLOR SCHEME ============
      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        primaryContainer: primary,
        secondary: secondary,
        tertiary: accent,
        error: error,
        surface: grey700,
        outline: grey600,
      ),

      // ============ APP BAR THEME ============
      appBarTheme: const AppBarTheme(
        backgroundColor: grey800,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: white,
          fontSize: AppFontSize.xl,
          fontWeight: FontWeight.bold,
        ),
      ),

      // ============ TEXT THEMES ============
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: AppFontSize.h1,
          fontWeight: FontWeight.bold,
          color: white,
        ),
        displayMedium: TextStyle(
          fontSize: AppFontSize.h2,
          fontWeight: FontWeight.bold,
          color: white,
        ),
        displaySmall: TextStyle(
          fontSize: AppFontSize.h3,
          fontWeight: FontWeight.bold,
          color: white,
        ),
        headlineMedium: TextStyle(
          fontSize: AppFontSize.h4,
          fontWeight: FontWeight.bold,
          color: white,
        ),
        headlineSmall: TextStyle(
          fontSize: AppFontSize.h5,
          fontWeight: FontWeight.bold,
          color: white,
        ),
        titleLarge: TextStyle(
          fontSize: AppFontSize.h6,
          fontWeight: FontWeight.bold,
          color: white,
        ),
        titleMedium: TextStyle(
          fontSize: AppFontSize.xl,
          fontWeight: FontWeight.w600,
          color: white,
        ),
        titleSmall: TextStyle(
          fontSize: AppFontSize.lg,
          fontWeight: FontWeight.w600,
          color: grey200,
        ),
        bodyLarge: TextStyle(
          fontSize: AppFontSize.lg,
          fontWeight: FontWeight.normal,
          color: white,
        ),
        bodyMedium: TextStyle(
          fontSize: AppFontSize.base,
          fontWeight: FontWeight.normal,
          color: grey200,
        ),
        bodySmall: TextStyle(
          fontSize: AppFontSize.sm,
          fontWeight: FontWeight.normal,
          color: grey400,
        ),
        labelLarge: TextStyle(
          fontSize: AppFontSize.base,
          fontWeight: FontWeight.w600,
          color: primaryLight,
        ),
        labelMedium: TextStyle(
          fontSize: AppFontSize.sm,
          fontWeight: FontWeight.w600,
          color: grey200,
        ),
        labelSmall: TextStyle(
          fontSize: AppFontSize.xs,
          fontWeight: FontWeight.w600,
          color: grey400,
        ),
      ),

      // ============ BUTTON THEMES ============
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(
            vertical: AppPadding.md,
            horizontal: AppPadding.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          elevation: 2,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: primaryLight, width: 1.5),
          padding: const EdgeInsets.symmetric(
            vertical: AppPadding.md,
            horizontal: AppPadding.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          padding: const EdgeInsets.symmetric(
            vertical: AppPadding.sm,
            horizontal: AppPadding.md,
          ),
        ),
      ),

      // ============ INPUT DECORATION THEME ============
      inputDecorationTheme: InputDecorationTheme(
        fillColor: grey700,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: AppPadding.md,
          horizontal: AppPadding.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: grey600),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: grey600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(
          color: grey200,
          fontSize: AppFontSize.base,
        ),
        hintStyle: const TextStyle(
          color: grey500,
          fontSize: AppFontSize.base,
        ),
      ),

      // ============ CARD THEME (Material 3) ============
      cardTheme: CardThemeData(
        color: grey700,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: grey600),
        ),
      ),

      // ============ DIALOG THEME (Material 3) ============
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        backgroundColor: grey800,
      ),

      // ============ BOTTOM SHEET THEME ============
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.xl),
            topRight: Radius.circular(AppRadius.xl),
          ),
        ),
        backgroundColor: grey800,
      ),

      // ============ DIVIDER THEME ============
      dividerTheme: const DividerThemeData(
        color: grey600,
        thickness: 1,
        space: AppPadding.md,
      ),
    );
  }
}