import 'package:dio_cache_plus/dio_cache_plus.dart';

import '../config/network_config.dart';

/// Creates a cache interceptor with the given configuration.
///
/// Uses dio_cache_plus for enhanced caching with per-request control.
DioCachePlusInterceptor createCacheInterceptor(NetworkConfig config) {
  return DioCachePlusInterceptor(
    // Don't cache all requests by default
    cacheAll: false,

    // Default cache duration
    commonCacheDuration: config.defaultCacheDuration,

    // Consider non-200 responses as errors (don't cache them)
    isErrorResponse: (response) => response.statusCode != 200,

    // Conditional caching rules
    conditionalRules: [
      // Cache GET requests to common endpoints longer
      ConditionalCacheRule.duration(
        condition: (request) =>
            request.method == 'GET' &&
            (request.url.contains('/config') ||
                request.url.contains('/settings')),
        duration: const Duration(hours: 1),
      ),
    ],
  );
}

/// Extension to easily enable caching on requests
extension CacheOptionsExtension on Map<String, dynamic> {
  /// Enables caching for this request with optional duration
  Map<String, dynamic> withCache({Duration? duration}) {
    return {
      ...this,
      'enableCache': true,
      if (duration != null) 'cacheDuration': duration,
    };
  }

  /// Disables caching for this request
  Map<String, dynamic> withoutCache() {
    return {...this, 'enableCache': false};
  }

  /// Forces a fresh request, ignoring cache
  Map<String, dynamic> forceRefresh() {
    return {...this, 'forceRefresh': true};
  }
}
