import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Logo Colors
  static const Color primaryBlue = Color(0xFF0099FF); // Neon/Electric Blue
  static const Color primaryRed = Color(0xFFFF3300); // Fiery Red/Orange

  // Light Mode Colors
  static const Color backgroundLight = Color(0xFFF9FAFB); // Very light grey, easy on eyes
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textLightPrimary = Color(0xFF111827); // Dark gray for high contrast
  static const Color textLightSecondary = Color(0xFF4B5563);
  
  // Dark Mode Colors
  static const Color backgroundDark = Color(0xFF0F172A); // Slate dark
  static const Color cardDark = Color(0xFF1E293B); 
  static const Color textDarkPrimary = Color(0xFFF9FAFB); 
  static const Color textDarkSecondary = Color(0xFF9CA3AF);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: primaryRed,
        surface: cardDark,
        onSurface: textDarkPrimary,
      ),
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.cairo(color: textDarkPrimary, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.cairo(color: textDarkPrimary, fontWeight: FontWeight.bold),
        bodyLarge: GoogleFonts.cairo(color: textDarkPrimary),
        bodyMedium: GoogleFonts.cairo(color: textDarkSecondary),
        titleLarge: GoogleFonts.cairo(color: textDarkPrimary, fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.cairo(color: textDarkPrimary, fontWeight: FontWeight.w600),
        labelLarge: GoogleFonts.cairo(color: textDarkPrimary, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDarkPrimary),
        titleTextStyle: GoogleFonts.cairo(color: textDarkPrimary, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.1), thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
          elevation: 4,
          shadowColor: primaryBlue.withValues(alpha: 0.4),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        labelStyle: TextStyle(color: textDarkSecondary),
        hintStyle: TextStyle(color: textDarkSecondary.withValues(alpha: 0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed.withValues(alpha: 0.8), width: 1),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: primaryRed,
        surface: cardLight,
        onSurface: textLightPrimary,
      ),
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.cairo(color: textLightPrimary, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.cairo(color: textLightPrimary, fontWeight: FontWeight.bold),
        bodyLarge: GoogleFonts.cairo(color: textLightPrimary),
        bodyMedium: GoogleFonts.cairo(color: textLightSecondary),
        titleLarge: GoogleFonts.cairo(color: textLightPrimary, fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.cairo(color: textLightPrimary, fontWeight: FontWeight.w600),
        labelLarge: GoogleFonts.cairo(color: textLightPrimary, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textLightPrimary),
        titleTextStyle: GoogleFonts.cairo(color: textLightPrimary, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(color: Colors.black.withValues(alpha: 0.05), thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
          elevation: 4,
          shadowColor: primaryBlue.withValues(alpha: 0.3),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(color: textLightSecondary),
        hintStyle: TextStyle(color: textLightSecondary.withValues(alpha: 0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed.withValues(alpha: 0.8), width: 1),
        ),
      ),
    );
  }
}
