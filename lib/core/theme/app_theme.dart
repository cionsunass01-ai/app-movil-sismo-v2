import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.slate100,
      primaryColor: AppColors.primaryRed,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryRed,
        secondary: AppColors.safeGreen,
        tertiary: AppColors.warningAmber,
        surface: AppColors.white,
        error: AppColors.primaryRed,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: AppColors.slate900,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.slate900,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.slate900,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.slate900,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: AppColors.slate800),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AppColors.slate600,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.slate950,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.slate200),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.slate50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.slate300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.slate300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}
