import 'package:flutter/material.dart';

/// Design system tokens faithfully implementing InstaLens Dynamic Dark M3 from Stitch.
class AppTheme {
  // Brand Palette
  static const Color primary = Color(0xFFE1306C); // Vibrant Rose Magenta
  static const Color primaryContainer = Color(0xFFFF4C83);
  static const Color secondary = Color(0xFF833AB4); // Electric Orchid Purple
  static const Color secondaryContainer = Color(0xFF6A1C9B);
  static const Color tertiary = Color(0xFFF77737); // Warm Solar Amber
  static const Color tertiaryContainer = Color(0xFFE86C2D);

  // Surface Hierarchy
  static const Color background = Color(0xFF111317);
  static const Color surface = Color(0xFF111317);
  static const Color surfaceContainerLowest = Color(0xFF0C0E12);
  static const Color surfaceContainerLow = Color(0xFF1A1C20);
  static const Color surfaceContainer = Color(0xFF1E2024);
  static const Color surfaceContainerHigh = Color(0xFF282A2E);
  static const Color surfaceContainerHighest = Color(0xFF333539);

  // Text & Outlines
  static const Color onSurface = Color(0xFFE2E2E8);
  static const Color onSurfaceVariant = Color(0xFFA9898E);
  static const Color outline = Color(0xFF383E49);
  static const Color outlineVariant = Color(0x1FFFFFFF);

  // Semantics
  static const Color error = Color(0xFFFF5252);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color success = Color(0xFF00E676);

  // Signature Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [secondary, primary, tertiary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient ringGradient = LinearGradient(
    colors: [secondary, primary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [Color(0x33833AB4), Color(0x33E1306C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primaryContainer,
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: secondaryContainer,
        tertiary: tertiary,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      cardTheme: CardTheme(
        color: surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x14FFFFFF), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x1FFFFFFF), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x1FFFFFFF), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: onSurfaceVariant, fontSize: 14),
      ),
    );
  }
}

