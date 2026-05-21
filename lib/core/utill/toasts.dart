import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../navigation/navigation_helper.dart';

/// Toast notification helper using toastification package.
///
/// Provides consistent toast notifications throughout the app
/// with success, error, warning, and info variants.
///
/// **Usage in pages (with context)**:
/// ```dart
/// AppToast.success(context, 'Operation successful!');
/// AppToast.error(context, 'Something went wrong', description: 'Please try again');
/// ```
///
/// **Usage in controllers (without context)**:
/// ```dart
/// AppToast.showSuccess('Operation successful!');
/// AppToast.showError('Something went wrong');
/// ```
class AppToast {
  AppToast._();

  /// Get current context from NavigationService
  static BuildContext? get _context =>
      NavigationService.navigatorKey.currentContext;

  /// Show success toast (with context)
  static void success(
    BuildContext context,
    String message, {
    String? description,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      title: Text(message),
      description: description != null ? Text(description) : null,
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
      animationBuilder: (context, animation, alignment, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      borderRadius: BorderRadius.circular(12.0),
      dragToClose: true,
    );
  }

  /// Show error toast (with context)
  static void error(
    BuildContext context,
    String message, {
    String? description,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flatColored,
      title: Text(message),
      description: description != null ? Text(description) : null,
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
      animationBuilder: (context, animation, alignment, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      borderRadius: BorderRadius.circular(12.0),
      dragToClose: true,
    );
  }

  /// Show warning toast (with context)
  static void warning(
    BuildContext context,
    String message, {
    String? description,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.warning,
      style: ToastificationStyle.flatColored,
      title: Text(message),
      description: description != null ? Text(description) : null,
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
      animationBuilder: (context, animation, alignment, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      borderRadius: BorderRadius.circular(12.0),
      dragToClose: true,
    );
  }

  /// Show info toast (with context)
  static void info(
    BuildContext context,
    String message, {
    String? description,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flatColored,
      title: Text(message),
      description: description != null ? Text(description) : null,
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
      animationBuilder: (context, animation, alignment, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      borderRadius: BorderRadius.circular(12.0),
      dragToClose: true,
    );
  }

  // ========================================
  // CONTROLLER METHODS (without context)
  // ========================================

  /// Show success toast from controller (no context needed)
  static void showSuccess(String message, {String? description}) {
    if (_context != null) {
      success(_context!, message, description: description);
    }
  }

  /// Show error toast from controller (no context needed)
  static void showError(String message, {String? description}) {
    if (_context != null) {
      error(_context!, message, description: description);
    }
  }

  /// Show warning toast from controller (no context needed)
  static void showWarning(String message, {String? description}) {
    if (_context != null) {
      warning(_context!, message, description: description);
    }
  }

  /// Show info toast from controller (no context needed)
  static void showInfo(String message, {String? description}) {
    if (_context != null) {
      info(_context!, message, description: description);
    }
  }
}
