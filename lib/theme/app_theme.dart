import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFF6F7FB);

  // Primary gradient
  static const Color primaryStart = Color(0xFF6A5AE0);
  static const Color primaryEnd = Color(0xFF4FC3F7);

  // Card colors (vibrant but soft)
  static const Color cardPurple = Color(0xFFEDEBFF);
  static const Color cardBlue = Color(0xFFE3F2FD);
  static const Color cardPink = Color(0xFFFFEBEE);
  static const Color cardGreen = Color(0xFFE8F5E9);

  // Text
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF6E6E73);
  static const Color textMuted = Color(0xFF9E9E9E);

  // UI
  static const Color border = Color(0xFFE0E0E0);
  static const Color shadow = Colors.black12;
}

class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primaryStart, AppColors.primaryEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle small = TextStyle(
    fontSize: 12,
    color: AppColors.textMuted,
  );
}

class AppSpacing {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppRadius {
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
}

class AppShadows {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.shadow.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'SF Pro Display',

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),

      textTheme: const TextTheme(
        headlineLarge: AppTextStyles.title,
        bodyMedium: AppTextStyles.body,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          elevation: 0,
          backgroundColor: AppColors.primaryStart,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.primaryStart,
        labelStyle: const TextStyle(color: AppColors.textPrimary),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.all(AppColors.primaryStart),
        trackColor: MaterialStateProperty.all(
          AppColors.primaryStart.withOpacity(0.4),
        ),
      ),
    );
  }
}