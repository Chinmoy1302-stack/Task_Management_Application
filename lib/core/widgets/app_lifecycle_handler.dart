import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/version_update_service.dart';
import '../services/in_app_review_service.dart';

/// Widget that handles app lifecycle events for version updates and reviews
class AppLifecycleHandler extends StatefulWidget {
  final Widget child;

  const AppLifecycleHandler({super.key, required this.child});

  @override
  State<AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends State<AppLifecycleHandler>
    with WidgetsBindingObserver {
  final VersionUpdateService _versionUpdateService = VersionUpdateService();
  final InAppReviewService _reviewService = InAppReviewService();

  static const String _appLaunchCountKey = 'app_launch_count';
  int _appLaunchCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLaunchCount();
    _initializeServices();
  }

  /// Load app launch count from SharedPreferences
  Future<void> _loadLaunchCount() async {
    final prefs = await SharedPreferences.getInstance();
    _appLaunchCount = prefs.getInt(_appLaunchCountKey) ?? 0;
    _appLaunchCount++;
    await prefs.setInt(_appLaunchCountKey, _appLaunchCount);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Initialize services on app start
  Future<void> _initializeServices() async {
    // Check for updates on app start (with delay to not interrupt initial load)
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      await _versionUpdateService.checkForUpdates(context);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  /// Handle app resume - check for updates and potentially request review
  Future<void> _onAppResumed() async {
    if (!mounted) return;

    // Check for updates when app resumes
    await _versionUpdateService.checkForUpdates(context);

    // Handle review request (launch count already incremented on init)
    await _handleReviewRequest();
  }

  /// Handle review request based on app usage
  Future<void> _handleReviewRequest() async {
    // Request review after 3 app launches (user has used the app enough)
    if (_appLaunchCount >= 3 && _appLaunchCount % 5 == 0) {
      // Check if review can be requested
      final canRequest = await _reviewService.canRequestReview();
      if (canRequest && mounted) {
        // Small delay to not interrupt user flow
        await Future.delayed(const Duration(seconds: 1));
        await _reviewService.requestReview();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
