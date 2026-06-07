import 'package:flutter/material.dart';

/// App color palette + theme for My Shelf (admyhusky.dev look).
class AppColors {
  static const cream = Color(0xFFFFF8E7);
  static const navy = Color(0xFF1B1B3A);
  static const yellow = Color(0xFFFFD93D);
  static const mint = Color(0xFF4ECDC4);
  static const coral = Color(0xFFFF6B6B);
  static const lavender = Color(0xFFB19CD9);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.yellow,
        primary: AppColors.navy,
        secondary: AppColors.mint,
        error: AppColors.coral,
        surface: AppColors.cream,
      ),
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.navy,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.navy,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w800,
        ),
        bodyMedium: const TextStyle(color: AppColors.navy),
      ),
    );
  }
}
