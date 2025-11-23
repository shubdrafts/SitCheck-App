import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color beige = Color(0xFFF5E6D3);
  static const Color primaryRed = Color(0xFFB3261E);
  static const Color green = Color(0xFF2E7D32);
  static const Color yellow = Color(0xFFF9A825);
  static const Color red = Color(0xFFD32F2F);
  static const Color cardShadow = Color(0x14000000);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color lightText = Color(0xFF6B6B6B);
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color softBlue = Color(0xFF4A90E2);
  static const Color gradientStart = Color(0xFFFFF8F3);
  static const Color gradientEnd = Color(0xFFF5E6D3);
}

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light();
    final interTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: const Color(0xFF2B2B2B),
      displayColor: const Color(0xFF2B2B2B),
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.beige,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primaryRed,
        secondary: AppColors.yellow,
        surface: Colors.white,
      ),
      textTheme: interTheme.copyWith(
        headlineLarge: GoogleFonts.montserrat(textStyle: base.textTheme.headlineLarge),
        headlineMedium: GoogleFonts.montserrat(textStyle: base.textTheme.headlineMedium),
        headlineSmall: GoogleFonts.montserrat(textStyle: base.textTheme.headlineSmall),
        titleLarge: GoogleFonts.montserrat(textStyle: base.textTheme.titleLarge),
        titleMedium: GoogleFonts.montserrat(textStyle: base.textTheme.titleMedium),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Color(0xFF2B2B2B),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        shadowColor: AppColors.cardShadow,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            fontSize: 16,
          ),
        ).copyWith(
          backgroundColor: WidgetStateProperty.all(AppColors.primaryRed),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.1)),
          elevation: WidgetStateProperty.all(3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryRed,
          side: const BorderSide(color: AppColors.primaryRed, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryRed,
        unselectedItemColor: Colors.black45,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}