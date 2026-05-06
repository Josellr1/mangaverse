// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFF080B14);
  static const bgCard = Color(0xFF0F1220);
  static const bgSurface = Color(0xFF141828);
  static const primary = Color(0xFF8B5CF6);
  static const secondary = Color(0xFF06B6D4);
  static const textMain = Color(0xFFF1F5F9);
  static const textMuted = Color(0xFF94A3B8);
  static const border = Color(0x14FFFFFF);
  static const error = Color(0xFFEF4444);

  static const gradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.bgCard,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: AppColors.textMain,
        displayColor: AppColors.textMain,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xCC080B14),
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textMain),
        titleTextStyle: TextStyle(
          color: AppColors.textMain,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xF0080B14),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }
}
