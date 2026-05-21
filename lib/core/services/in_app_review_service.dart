import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle in-app review prompts
///
/// Follows platform guidelines:
/// - Android: Has quota limits, should not be triggered frequently
/// - iOS: Can be tested on simulator, but real reviews only in production
class InAppReviewService {
  static const String _lastReviewRequestKey = 'last_review_request_timestamp';
  static const String _reviewRequestCountKey = 'review_request_count';
  static const String _reviewDismissedKey = 'review_dismissed';

  // Minimum time between review requests (30 days)
  static const Duration _minTimeBetweenRequests = Duration(days: 30);

  // Maximum number of review requests (to respect quota)
  static const int _maxReviewRequests = 3;

  final InAppReview _inAppReview = InAppReview.instance;

  /// Request in-app review if conditions are met
  ///
  /// This method checks:
  /// - If review is available on the platform
  /// - If enough time has passed since last request
  /// - If maximum request count hasn't been exceeded
  ///
  /// Returns true if review was requested, false otherwise
  Future<bool> requestReview() async {
    try {
      // Check if review is available
      if (!await _inAppReview.isAvailable()) {
        debugPrint('In-app review is not available on this platform');
        return false;
      }

      // Check if we should skip review request
      if (await _shouldSkipReviewRequest()) {
        debugPrint('Skipping review request - conditions not met');
        return false;
      }

      // Request review
      await _inAppReview.requestReview();

      // Save the request timestamp and increment count
      await _saveReviewRequest();

      debugPrint('In-app review requested successfully');
      return true;
    } catch (e) {
      debugPrint('In-app review service error: $e');
      return false;
    }
  }

  /// Open store listing for review (always available, not quota-limited)
  ///
  /// Use this for a permanent "Rate Us" button or similar call-to-action
  ///
  /// [appStoreId] - iOS App Store ID (optional, will be detected if not provided)
  /// [microsoftStoreId] - Microsoft Store ID (optional, for Windows)
  Future<void> openStoreListing({
    String? appStoreId,
    String? microsoftStoreId,
  }) async {
    try {
      await _inAppReview.openStoreListing(
        appStoreId: appStoreId,
        microsoftStoreId: microsoftStoreId,
      );
      debugPrint('Store listing opened');
    } catch (e) {
      debugPrint('Error opening store listing: $e');
    }
  }

  /// Check if review request should be skipped
  Future<bool> _shouldSkipReviewRequest() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if review was dismissed permanently
    final dismissed = prefs.getBool(_reviewDismissedKey) ?? false;
    if (dismissed) {
      return true;
    }

    // Check request count
    final requestCount = prefs.getInt(_reviewRequestCountKey) ?? 0;
    if (requestCount >= _maxReviewRequests) {
      return true;
    }

    // Check time since last request
    final lastRequestTimestamp = prefs.getInt(_lastReviewRequestKey);
    if (lastRequestTimestamp != null) {
      final lastRequest = DateTime.fromMillisecondsSinceEpoch(
        lastRequestTimestamp,
      );
      final now = DateTime.now();
      final difference = now.difference(lastRequest);

      if (difference < _minTimeBetweenRequests) {
        return true;
      }
    }

    return false;
  }

  /// Save review request timestamp and increment count
  Future<void> _saveReviewRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final currentCount = prefs.getInt(_reviewRequestCountKey) ?? 0;

    await prefs.setInt(_lastReviewRequestKey, now);
    await prefs.setInt(_reviewRequestCountKey, currentCount + 1);
  }

  /// Mark review as dismissed (user doesn't want to be asked again)
  Future<void> markReviewDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reviewDismissedKey, true);
  }

  /// Reset review service state (for testing or if user wants to be asked again)
  Future<void> resetReviewState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastReviewRequestKey);
    await prefs.remove(_reviewRequestCountKey);
    await prefs.remove(_reviewDismissedKey);
  }

  /// Check if review can be requested (without actually requesting)
  Future<bool> canRequestReview() async {
    if (!await _inAppReview.isAvailable()) {
      return false;
    }
    return !await _shouldSkipReviewRequest();
  }
}
