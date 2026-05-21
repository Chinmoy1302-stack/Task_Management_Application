import 'package:dio/dio.dart';

/// Manages cancel tokens for network requests.
///
/// Provides per-feature/screen cancel token management for easy cleanup
/// when navigating away from screens or disposing widgets.
///
/// **Usage:**
/// ```dart
/// // In your screen/bloc/controller
/// final tokenManager = CancelTokenManager();
///
/// // Create a token for this feature
/// final token = tokenManager.createToken('user_profile');
///
/// // Use in API calls
/// await api.get(endpoint: '/user', cancelToken: token, ...);
///
/// // Cancel when leaving screen (e.g., in dispose)
/// tokenManager.cancel('user_profile');
///
/// // Or cancel all
/// tokenManager.cancelAll();
/// ```
class CancelTokenManager {
  // Singleton instance
  static final CancelTokenManager _instance = CancelTokenManager._internal();

  factory CancelTokenManager() => _instance;

  CancelTokenManager._internal();

  /// Map of feature/screen names to their cancel tokens
  final Map<String, CancelToken> _tokens = {};

  /// Creates a new cancel token for the given feature/screen.
  ///
  /// If a token already exists for this key, it will be cancelled first
  /// before creating a new one.
  ///
  /// [key] - Unique identifier for the feature/screen (e.g., 'user_profile', 'home_feed')
  CancelToken createToken(String key) {
    // Cancel existing token if present
    if (_tokens.containsKey(key)) {
      cancel(key);
    }

    final token = CancelToken();
    _tokens[key] = token;
    return token;
  }

  /// Gets an existing token for the given key, or creates a new one if not found.
  CancelToken getOrCreateToken(String key) {
    if (_tokens.containsKey(key) && !_tokens[key]!.isCancelled) {
      return _tokens[key]!;
    }
    return createToken(key);
  }

  /// Gets an existing token for the given key, or null if not found.
  CancelToken? getToken(String key) {
    final token = _tokens[key];
    if (token != null && !token.isCancelled) {
      return token;
    }
    return null;
  }

  /// Cancels the token for the given key and removes it.
  ///
  /// [reason] - Optional reason for cancellation
  void cancel(String key, [String? reason]) {
    final token = _tokens[key];
    if (token != null && !token.isCancelled) {
      token.cancel(reason ?? 'Request cancelled for: $key');
    }
    _tokens.remove(key);
  }

  /// Cancels all active tokens.
  ///
  /// Useful for app-wide cleanup (e.g., on logout)
  void cancelAll([String? reason]) {
    for (final entry in _tokens.entries) {
      if (!entry.value.isCancelled) {
        entry.value.cancel(reason ?? 'All requests cancelled');
      }
    }
    _tokens.clear();
  }

  /// Checks if a token exists and is not cancelled for the given key.
  bool hasActiveToken(String key) {
    final token = _tokens[key];
    return token != null && !token.isCancelled;
  }

  /// Gets all active token keys.
  List<String> get activeKeys => _tokens.entries
      .where((e) => !e.value.isCancelled)
      .map((e) => e.key)
      .toList();

  /// Clears all tokens without cancelling them.
  ///
  /// Use with caution - prefer [cancelAll] in most cases.
  void clear() {
    _tokens.clear();
  }
}
