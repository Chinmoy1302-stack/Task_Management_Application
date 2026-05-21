/// Route path constants for the application.
///
/// This provides a centralized place for all route paths,
/// making it easy to maintain and preventing typos.
class RouteConstants {
  RouteConstants._();

  // Root
  static const String root = '/';

  // Auth Routes
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Main Routes
  static const String tasks = '/tasks';
  static const String profile = '/profile';

  // Profile Nested Routes
  static const String themeSelection = 'theme';
}
