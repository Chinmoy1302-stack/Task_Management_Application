import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_constants.dart';
import 'app_router.dart';

/// Navigation helper for use in controllers and services
/// where BuildContext is not available.
class NavigationHelper {
  NavigationHelper._();

  static GoRouter get _router {
    return AppRouter.router;
  }

  // Auth Routes
  static void toLogin() => _router.go(RouteConstants.login);

  // Main Routes
  static void toTasks() => _router.go(RouteConstants.tasks);

  static void toProfile() => _router.go(RouteConstants.profile);

  // Navigation actions
  static void back() {
    if (_router.canPop()) {
      _router.pop();
    }
  }
}

/// Service to hold the global navigator key
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}
