import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_theme_type.dart';
import 'theme_controller.dart';

/// App-wide color palette. Update here to change buttons, pages, and accents.
class AppColors {
  AppColors._();

  // Brand — Indigo / violet
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Light mode surfaces
  static const Color _backgroundLight = Color(0xFFF8FAFC);
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _textPrimaryLight = Color(0xFF0F172A);
  static const Color _textSecondaryLight = Color(0xFF64748B);
  static const Color _borderLight = Color(0xFFE2E8F0);

  // Dark mode surfaces
  static const Color _backgroundDark = Color(0xFF0F1117);
  static const Color _surfaceDark = Color(0xFF1A1D27);
  static const Color _textPrimaryDark = Color(0xFFF1F5F9);
  static const Color _textSecondaryDark = Color(0xFF94A3B8);
  static const Color _borderDark = Color(0xFF2D3348);

  // Semantic
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color onWarning = Color(0xFFFFFFFF);

  static Color get background => _isDarkMode ? _backgroundDark : _backgroundLight;
  static Color get surface => _isDarkMode ? _surfaceDark : _surfaceLight;
  static Color get textPrimary => _isDarkMode ? _textPrimaryDark : _textPrimaryLight;
  static Color get textSecondary =>
      _isDarkMode ? _textSecondaryDark : _textSecondaryLight;
  static Color get textDisabled =>
      _isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
  static Color get divider => _isDarkMode ? _borderDark : _borderLight;
  static Color get border => divider;

  static Color get primaryTint =>
      primary.withValues(alpha: _isDarkMode ? 0.2 : 0.12);

  static bool get _isDarkMode {
    try {
      final controller = Get.find<ThemeController>();
      final theme = controller.currentTheme;
      if (theme == AppThemeMode.dark) return true;
      if (theme == AppThemeMode.light) return false;
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    } catch (e) {
      return false;
    }
  }

  // Backwards compatibility
  static Color get white => Colors.white;
  static Color get black => Colors.black;
  static Color get transparent => Colors.transparent;
  /// Backwards-compatible accent (green); use [success] for new code.
  static Color get accent => success;
  static Color get textWhite => Colors.white;
  static Color get textWhite70 => Colors.white70;
  static Color get primaryLegacy => primary;
  static Color get secondary => primaryLight;
  static Color get glassBackground => surface;
  static Color get glassBorder => border;

  static LinearGradient get mainGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, primaryLight],
      );
}
