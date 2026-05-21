import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';

import '../config/network_config.dart';
import '../interceptors/auth_interceptor.dart';
import '../interceptors/cache_interceptor.dart';
import '../interceptors/logging_interceptor.dart';
import '../interceptors/retry_interceptor.dart';

/// Factory class for creating and configuring Dio instances.
///
/// Creates a singleton Dio instance with all interceptors pre-configured
/// based on the provided [NetworkConfig].
class DioClient {
  static Dio? _instance;
  static NetworkConfig? _config;

  /// Private constructor
  DioClient._();

  /// Gets the singleton Dio instance.
  ///
  /// Must call [initialize] before accessing this.
  static Dio get instance {
    if (_instance == null) {
      throw StateError(
        'DioClient has not been initialized. '
        'Call DioClient.initialize() first.',
      );
    }
    return _instance!;
  }

  /// Checks if the client has been initialized.
  static bool get isInitialized => _instance != null;

  /// Gets the current configuration.
  static NetworkConfig? get config => _config;

  /// Initializes the Dio client with the given configuration.
  ///
  /// This should be called once during app startup, typically in main.dart.
  ///
  /// [config] - Network configuration settings
  /// [tokenProvider] - Optional function to get the current access token
  /// [tokenRefreshHandler] - Optional function to handle token refresh
  /// [onTokenRefreshFailed] - Optional callback when token refresh fails
  static Dio initialize({
    required NetworkConfig config,
    String? Function()? tokenProvider,
    Future<Map<String, String>?> Function()? tokenRefreshHandler,
    VoidCallback? onTokenRefreshFailed,
  }) {
    _config = config;

    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout: config.sendTimeout,
        responseType: ResponseType.json,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors in order
    _addInterceptors(
      dio,
      config,
      tokenProvider: tokenProvider,
      tokenRefreshHandler: tokenRefreshHandler,
      onTokenRefreshFailed: onTokenRefreshFailed,
    );

    _instance = dio;
    return dio;
  }

  /// Creates a new Dio instance without affecting the singleton.
  ///
  /// Useful for creating isolated instances for specific use cases.
  static Dio createInstance({
    required NetworkConfig config,
    String? Function()? tokenProvider,
    Future<Map<String, String>?> Function()? tokenRefreshHandler,
    VoidCallback? onTokenRefreshFailed,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout: config.sendTimeout,
        responseType: ResponseType.json,
      ),
    );

    _addInterceptors(
      dio,
      config,
      tokenProvider: tokenProvider,
      tokenRefreshHandler: tokenRefreshHandler,
      onTokenRefreshFailed: onTokenRefreshFailed,
    );

    return dio;
  }

  static void _addInterceptors(
    Dio dio,
    NetworkConfig config, {
    String? Function()? tokenProvider,
    Future<Map<String, String>?> Function()? tokenRefreshHandler,
    VoidCallback? onTokenRefreshFailed,
  }) {
    // 1. Auth interceptor (first to add tokens)
    if (tokenProvider != null) {
      dio.interceptors.add(
        AuthInterceptor(
          tokenProvider: tokenProvider,
          refreshTokenHandler: tokenRefreshHandler,
          onRefreshFailed: onTokenRefreshFailed,
        ),
      );
    }

    // 2. Cache interceptor
    if (config.enableCaching) {
      dio.interceptors.add(createCacheInterceptor(config));
    }

    // 3. Retry interceptor
    if (config.enableRetry) {
      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          logPrint: config.enableLogging
              ? (message) => debugPrint('[Retry] $message')
              : null,
          retries: config.retryCount,
          retryDelays: config.retryDelays,
        ),
      );
    }

    // 4. Logging interceptor (last to see final request/response)
    if (config.enableLogging && kDebugMode) {
      dio.interceptors.add(const LoggingInterceptor());
    }
  }

  /// Resets the singleton instance.
  ///
  /// Useful for testing or when reinitializing with different config.
  static void reset() {
    _instance = null;
    _config = null;
  }
}
