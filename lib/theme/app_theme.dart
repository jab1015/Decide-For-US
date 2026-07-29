import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFFFFBF7);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF252238);
  static const muted = Color(0xFF716D7C);
  static const primary = Color(0xFF6255D9);
  static const primaryDark = Color(0xFF473BAF);
  static const primaryStart = primary;
  static const primaryEnd = Color(0xFF8878EE);
  static const coral = Color(0xFFFF8066);
  static const lavender = Color(0xFFF0EDFF);
  static const peach = Color(0xFFFFEEE8);
  static const mint = Color(0xFFE9F7EF);
  static const sky = Color(0xFFEAF4FF);
  static const border = Color(0xFFEAE5E0);
}

class AppGradients {
  static const primary = LinearGradient(
    colors: [AppColors.primary, Color(0xFF8878EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const dateNight = LinearGradient(
    colors: [Color(0xFFFFF0ED), Color(0xFFF4EEFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppSpacing {
  static const xs = 6.0;
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppRadius {
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 26.0;
}

class AppShadows {
  static final soft = [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.07),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
}

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'SF Pro Display',
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: AppColors.ink,
          fontSize: 30,
          height: 1.08,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineSmall: TextStyle(
          color: AppColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleMedium: TextStyle(
          color: AppColors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: AppColors.muted,
          fontSize: 16,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          color: AppColors.muted,
          fontSize: 14,
          height: 1.4,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

