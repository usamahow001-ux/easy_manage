import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryGreen = Color(0xFF0D9488); // Modern Teal / Emerald
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFF2DD4BF);
  static const Color primarySurfaceLight = Color(0xFFF0FDFA);
  static const Color primarySurfaceDark = Color(0xFF132F2B);
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentPurple = Color(0xFF8B5CF6);

  // Financial Semantics
  static const Color debitRed = Color(0xFFEF4444); // You Gave / Money Out
  static const Color debitRedDark = Color(0xFFDC2626);
  static const Color debitRedLight = Color(0xFFFEE2E2);
  static const Color creditGreen = Color(0xFF10B981); // You Got / Money In
  static const Color creditGreenDark = Color(0xFF059669);
  static const Color creditGreenLight = Color(0xFFD1FAE5);

  // Neutral Colors (Light Mode)
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardElevated = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextMuted = Color(0xFF94A3B8);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Neutral Colors (Dark Mode)
  static const Color darkBg = Color(0xFF0B1120);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkCardElevated = Color(0xFF283548);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);
  static const Color darkBorder = Color(0xFF334155);

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.inter().fontFamily,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: primaryDark,
        surface: lightCard,
        error: debitRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightCard,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        iconTheme: const IconThemeData(color: lightTextPrimary),
        titleTextStyle: GoogleFonts.outfit(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        hintStyle: GoogleFonts.inter(color: lightTextMuted, fontSize: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightCard,
        indicatorColor: primaryGreen.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryGreen,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: lightTextSecondary,
          );
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.inter().fontFamily,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        secondary: primaryLight,
        surface: darkCard,
        error: debitRed,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: darkTextPrimary,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkCard,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        iconTheme: const IconThemeData(color: darkTextPrimary),
        titleTextStyle: GoogleFonts.outfit(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCardElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        hintStyle: GoogleFonts.inter(color: darkTextMuted, fontSize: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkCard,
        indicatorColor: primaryGreen.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryLight,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: darkTextSecondary,
          );
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
      ),
    );
  }
}
