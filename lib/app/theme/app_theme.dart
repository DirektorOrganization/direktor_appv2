import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _brandBlue = Color(0xFF0A66B7);
  static const _brandBlueDark = Color(0xFF084C8D);
  static const _brandOrange = Color(0xFFF5A623);
  static const _brandOrangeSoft = Color(0xFFFFF2DD);
  static const _surface = Colors.white;
  static const _background = Color(0xFFF3F6FA);
  static const _stroke = Color(0xFFD9E3F0);
  static const _text = Color(0xFF1E2B3A);
  static const _muted = Color(0xFF62748A);
  static const _darkSurface = Color(0xFF16202B);
  static const _darkBackground = Color(0xFF0D141C);
  static const _darkStroke = Color(0xFF243241);
  static const _darkText = Color(0xFFF2F6FB);
  static const _darkMuted = Color(0xFFA8B7C8);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _brandBlue,
      primary: _brandBlue,
      secondary: _brandOrange,
      brightness: Brightness.light,
      surface: _surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _background,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: _background,
        foregroundColor: _text,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _text, height: 1.15),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _text, height: 1.2),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _text, height: 1.2),
        bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _text, height: 1.4),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _text, height: 1.4),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _muted, height: 1.35),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _surface),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _text),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        hintStyle: const TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w500),
        labelStyle: const TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _brandBlue, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: _brandBlue,
          foregroundColor: _surface,
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _brandBlue,
          minimumSize: const Size(0, 44),
          side: const BorderSide(color: _stroke),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: _surface,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _brandBlue,
        foregroundColor: _surface,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _surface,
        selectedColor: _brandBlue.withOpacity(0.12),
        side: const BorderSide(color: _stroke),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _text),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      ),
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: _stroke),
        ),
      ),
      dividerTheme: const DividerThemeData(color: _stroke, thickness: 1),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _brandBlue,
      primary: _brandBlue,
      secondary: _brandOrange,
      brightness: Brightness.dark,
      surface: _darkSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _darkBackground,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: _darkBackground,
        foregroundColor: _darkText,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _darkText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _darkText, height: 1.15),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkText, height: 1.2),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _darkText, height: 1.2),
        bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _darkText, height: 1.4),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _darkText, height: 1.4),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _darkMuted, height: 1.35),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _darkText),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _darkText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        hintStyle: const TextStyle(color: _darkMuted, fontSize: 13, fontWeight: FontWeight.w500),
        labelStyle: const TextStyle(color: _darkMuted, fontSize: 13, fontWeight: FontWeight.w600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _darkStroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _darkStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _brandBlue, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: _brandBlue,
          foregroundColor: _darkText,
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkText,
          minimumSize: const Size(0, 44),
          side: const BorderSide(color: _darkStroke),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: _darkSurface,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _brandBlue,
        foregroundColor: _darkText,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _darkSurface,
        selectedColor: _brandBlue.withValues(alpha: 0.20),
        side: const BorderSide(color: _darkStroke),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _darkText),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      ),
      cardTheme: CardThemeData(
        color: _darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: _darkStroke),
        ),
      ),
      dividerTheme: const DividerThemeData(color: _darkStroke, thickness: 1),
      popupMenuTheme: PopupMenuThemeData(
        color: _darkSurface,
        textStyle: const TextStyle(color: _darkText, fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static Color get brandBlue => _brandBlue;
  static Color get brandBlueDark => _brandBlueDark;
  static Color get brandOrange => _brandOrange;
  static Color get brandOrangeSoft => _brandOrangeSoft;
  static Color get surface => _surface;
  static Color get background => _background;
  static Color get stroke => _stroke;
  static Color get text => _text;
  static Color get muted => _muted;
}


