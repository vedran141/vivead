import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _primaryLight = Color(0xFF7A0000);
  static const Color _primaryDark = Color(0xFF8E3C3C);

  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
        textStyle: base.displayLarge,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        textStyle: base.displayMedium,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: GoogleFonts.playfairDisplay(
        textStyle: base.displaySmall,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: GoogleFonts.playfairDisplay(
        textStyle: base.headlineLarge,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        textStyle: base.headlineMedium,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.playfairDisplay(
        textStyle: base.headlineSmall,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.playfairDisplay(
        textStyle: base.titleLarge,
        fontWeight: FontWeight.w600,
      ),

      titleMedium: GoogleFonts.lato(
        textStyle: base.titleMedium,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: GoogleFonts.lato(
        textStyle: base.titleSmall,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.lato(textStyle: base.bodyLarge),
      bodyMedium: GoogleFonts.lato(textStyle: base.bodyMedium),
      bodySmall: GoogleFonts.lato(textStyle: base.bodySmall),
      labelLarge: GoogleFonts.lato(
        textStyle: base.labelLarge,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: GoogleFonts.lato(textStyle: base.labelMedium),
      labelSmall: GoogleFonts.lato(textStyle: base.labelSmall),
    );
  }

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: _primaryLight,
            brightness: Brightness.light,
          ).copyWith(
            primary: _primaryLight,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
      scaffoldBackgroundColor: const Color(0xFFFFFBF8),
      appBarTheme: const AppBarTheme(
        backgroundColor: _primaryLight,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: _primaryLight,
        unselectedItemColor: Colors.black,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
    return base.copyWith(textTheme: _buildTextTheme(base.textTheme));
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: _primaryDark,
            brightness: Brightness.dark,
          ).copyWith(
            primary: _primaryDark,
            onPrimary: Colors.black,
            surface: Colors.black,
            onSurface: Colors.white,
          ),
      scaffoldBackgroundColor: const Color(0xFF070300),
      appBarTheme: const AppBarTheme(
        backgroundColor: _primaryDark,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: _primaryDark,
        unselectedItemColor: Colors.white,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
    return base.copyWith(textTheme: _buildTextTheme(base.textTheme));
  }
}
