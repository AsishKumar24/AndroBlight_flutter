import 'package:flutter/material.dart';

/// Light “dashboard” UI — lavender page, violet brand, soft cards (Njagani-style).

class AppTheme {
  static const Color pageBackground = Color(0xFFF5F5FA);
  /// Legacy name: used as scaffold / gradient end across screens.
  static const Color primaryDark = pageBackground;
  static const Color primaryMedium = Color(0xFFFFFFFF);
  static const Color primaryLight = Color(0xFFEEF2FF);

  static const Color brand = Color(0xFF8B5CF6);
  static const Color brandDark = Color(0xFF7C3AED);
  static const Color accentCyan = brand;
  static const Color accentBlue = brandDark;

  /// Text/icons on purple buttons & brand fills.
  static const Color onBrand = Color(0xFFFFFFFF);

  static const Color malwareRed = Color(0xFFEF4444);
  static const Color benignGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);

  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const Color surfaceDark = Color(0xFFF3F4F6);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: pageBackground,
      colorScheme: ColorScheme.light(
        primary: brand,
        secondary: brandDark,
        surface: surfaceLight,
        error: malwareRed,
        onPrimary: onBrand,
        onSecondary: onBrand,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: pageBackground,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: onBrand,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brand,
          side: const BorderSide(color: brand, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: brand),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: textMuted.withOpacity(0.35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: textMuted.withOpacity(0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: malwareRed, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: textMuted),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
        bodySmall: TextStyle(color: textMuted, fontSize: 12),
      ),
      iconTheme: const IconThemeData(color: brand, size: 24),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: brand,
        linearTrackColor: surfaceDark,
        circularTrackColor: surfaceDark,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(color: textMuted.withOpacity(0.25)),
    );
  }

  /// Prefer [lightTheme]. Kept for tests / older references.
  static ThemeData get darkTheme => lightTheme;
}
