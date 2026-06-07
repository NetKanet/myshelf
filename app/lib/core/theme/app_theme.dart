import 'package:flutter/material.dart';

/// App color palette + theme for My Shelf (admyhusky.dev look).
class AppColors {
  // Brand accents (same in light & dark)
  static const cream = Color(0xFFFFF8E7);
  static const navy = Color(0xFF1B1B3A);
  static const yellow = Color(0xFFFFD93D);
  static const mint = Color(0xFF4ECDC4);
  static const coral = Color(0xFFFF6B6B);
  static const lavender = Color(0xFFB19CD9);

  // Dark-mode tones
  static const darkBg = Color(0xFF14142A);
  static const darkSurface = Color(0xFF22223C);
  static const darkInk = Color(0xFFECEAF5);

  static bool _isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  /// Card / surface color (white in light, dark grey in dark).
  static Color surface(BuildContext c) =>
      _isDark(c) ? darkSurface : Colors.white;

  /// Primary text/icon color on the background (navy in light, light in dark).
  static Color ink(BuildContext c) => _isDark(c) ? darkInk : navy;
}

class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.cream;
    final ink = isDark ? AppColors.darkInk : AppColors.navy;
    final surface = isDark ? AppColors.darkSurface : AppColors.cream;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.yellow,
        brightness: brightness,
        primary: isDark ? AppColors.yellow : AppColors.navy,
        secondary: AppColors.mint,
        error: AppColors.coral,
        surface: surface,
      ),
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w800),
        bodyMedium: TextStyle(color: ink),
      ),
    );
  }
}
