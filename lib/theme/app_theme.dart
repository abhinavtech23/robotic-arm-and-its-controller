import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OgarmColors {
  // Core palette
  static const Color background = Color(0xFF0A0E21);
  static const Color backgroundLight = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFF16213E);

  // Accent palette
  static const Color orange = Color(0xFFFF5722);
  static const Color orangeDark = Color(0xFFE64A19);
  static const Color amber = Color(0xFFFFB800);
  static const Color amberDark = Color(0xFFCC9300);
  static const Color critical = Color(0xFFFF2D55);
  static const Color criticalDark = Color(0xFFCC0033);
  static const Color success = Color(0xFF00E676);

  // Glass
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassHighlight = Color(0x0DFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textMuted = Color(0x66FFFFFF);
}

class OgarmTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: OgarmColors.background,
      primaryColor: OgarmColors.orange,
      colorScheme: const ColorScheme.dark(
        primary: OgarmColors.orange,
        secondary: OgarmColors.amber,
        error: OgarmColors.critical,
        surface: OgarmColors.surface,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: OgarmColors.textPrimary,
          letterSpacing: 2,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: OgarmColors.textPrimary,
          letterSpacing: 1.5,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: OgarmColors.textPrimary,
          letterSpacing: 1,
        ),
        titleMedium: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: OgarmColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: OgarmColors.textSecondary,
        ),
        bodyMedium: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: OgarmColors.textSecondary,
        ),
        labelLarge: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: OgarmColors.orange,
          letterSpacing: 1,
        ),
        labelSmall: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: OgarmColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0D1127),
        selectedItemColor: OgarmColors.orange,
        unselectedItemColor: OgarmColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: OgarmColors.textPrimary,
          letterSpacing: 2,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    const Color darkText = Color(0xFF1A1A2E);
    const Color mutedText = Color(0xFF5A5A6E);
    
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: OgarmColors.orangeDark,
      dividerColor: Colors.black.withValues(alpha: 0.1),
      colorScheme: const ColorScheme.light(
        primary: OgarmColors.orangeDark,
        secondary: OgarmColors.amberDark,
        error: OgarmColors.criticalDark,
        surface: Colors.white,
        onSurface: darkText,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: darkText,
          letterSpacing: 2,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkText,
          letterSpacing: 1.5,
        ),
        displaySmall: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: darkText,
          letterSpacing: 1,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkText,
          letterSpacing: 1,
        ),
        titleMedium: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        bodyLarge: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: mutedText,
        ),
        bodyMedium: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: mutedText,
        ),
        bodySmall: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: mutedText,
        ),
        labelLarge: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: OgarmColors.orangeDark,
          letterSpacing: 1,
        ),
        labelMedium: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: mutedText,
        ),
        labelSmall: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: mutedText,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: OgarmColors.orangeDark,
        unselectedItemColor: mutedText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkText,
          letterSpacing: 2,
        ),
        iconTheme: const IconThemeData(color: darkText),
      ),
    );
  }
}
