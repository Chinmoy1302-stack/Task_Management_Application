import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Application theme — driven by [AppColors].
class AppTheme {
  AppTheme._();

  static ThemeData getTheme({bool isDarkMode = false}) {
    final background =
        isDarkMode ? const Color(0xFF12121A) : const Color(0xFFF5F6FA);
    final surface =
        isDarkMode ? const Color(0xFF1C1C28) : const Color(0xFFFFFFFF);
    final textPrimary =
        isDarkMode ? const Color(0xFFF3F4F8) : const Color(0xFF1A1D26);
    final textSecondary =
        isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final border =
        isDarkMode ? const Color(0xFF2E2E3D) : const Color(0xFFE2E5EE);

    return ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: surface,
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: textPrimary),
        displayMedium: AppTextStyles.displayMedium.copyWith(color: textPrimary),
        headlineLarge: AppTextStyles.heading1.copyWith(color: textPrimary),
        headlineMedium: AppTextStyles.heading2.copyWith(color: textPrimary),
        headlineSmall: AppTextStyles.heading3.copyWith(color: textPrimary),
        titleLarge: AppTextStyles.heading4.copyWith(color: textPrimary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: textPrimary),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: textSecondary),
        labelLarge: AppTextStyles.buttonText.copyWith(color: textPrimary),
        labelSmall: AppTextStyles.caption.copyWith(color: textSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: textSecondary),
        prefixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.buttonText,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 2,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return IconThemeData(color: textSecondary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color: textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.normal,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: border),
    );
  }
}
