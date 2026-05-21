import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized text styles for the application.
///
/// This class demonstrates using both:
/// - Local asset fonts (Lato) - bundled with the app
/// - Network fonts (Ubuntu) - downloaded via google_fonts package
///
/// Usage:
/// ```dart
/// Text('Hello', style: AppTextStyles.heading1)
/// Text('World', style: AppTextStyles.bodyMedium)
/// ```
class AppTextStyles {
  AppTextStyles._();

  // ========================================
  // HEADINGS - Using Local Lato Font
  // ========================================

  static const TextStyle heading1 = TextStyle(
    fontFamily: 'Lato',
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: 'Lato',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: 'Lato',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle heading4 = TextStyle(
    fontFamily: 'Lato',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // ========================================
  // BODY TEXT - Using Local Lato Font
  // ========================================

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Lato',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.white,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Lato',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Color(0xB3FFFFFF),
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Lato',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Color(0xB3FFFFFF),
    height: 1.4,
  );

  // ========================================
  // SPECIAL USE - Using Network Ubuntu Font
  // ========================================

  /// Example of network font usage (Ubuntu via GoogleFonts)
  /// These fonts are downloaded on first use
  static TextStyle get displayLarge => GoogleFonts.ubuntu(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
    letterSpacing: -1.0,
  );

  static TextStyle get displayMedium => GoogleFonts.ubuntu(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
    letterSpacing: -0.8,
  );

  /// Accent text using Ubuntu - good for CTAs, labels
  static TextStyle get buttonText => GoogleFonts.ubuntu(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    letterSpacing: 0.5,
  );

  static TextStyle get caption => GoogleFonts.ubuntu(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textWhite70,
  );

  // ========================================
  // UTILITY METHODS
  // ========================================

  /// Create a copy of a text style with modified properties
  ///
  /// Example:
  /// ```dart
  /// AppTextStyles.withColor(AppTextStyles.heading1, Colors.blue)
  /// ```
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  static TextStyle withSize(TextStyle style, double fontSize) {
    return style.copyWith(fontSize: fontSize);
  }

  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }
}
