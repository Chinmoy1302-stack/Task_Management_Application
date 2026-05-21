/// Network configuration class
///
/// Centralizes all network-related settings that can be easily
/// configured per project.
class NetworkConfig {
  /// Base URL for API endpoints
  final String baseUrl;

  /// Connection timeout duration
  final Duration connectTimeout;

  /// Receive timeout duration
  final Duration receiveTimeout;

  /// Send timeout duration
  final Duration sendTimeout;

  /// Number of retry attempts for failed requests
  final int retryCount;

  /// Delays between retry attempts
  final List<Duration> retryDelays;

  /// Default cache duration for cached requests
  final Duration defaultCacheDuration;

  /// Whether to enable request logging in debug mode
  final bool enableLogging;

  /// Whether to enable caching by default
  final bool enableCaching;

  /// Whether to enable smart retry by default
  final bool enableRetry;

  /// Token refresh endpoint (relative to baseUrl)
  final String? refreshTokenEndpoint;

  const NetworkConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.sendTimeout = const Duration(seconds: 30),
    this.retryCount = 3,
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 3),
    ],
    this.defaultCacheDuration = const Duration(minutes: 5),
    this.enableLogging = true,
    this.enableCaching = true,
    this.enableRetry = true,
    this.refreshTokenEndpoint,
  });

  /// Creates a copy of this config with the given overrides
  NetworkConfig copyWith({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    int? retryCount,
    List<Duration>? retryDelays,
    Duration? defaultCacheDuration,
    bool? enableLogging,
    bool? enableCaching,
    bool? enableRetry,
    String? refreshTokenEndpoint,
  }) {
    return NetworkConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      retryCount: retryCount ?? this.retryCount,
      retryDelays: retryDelays ?? this.retryDelays,
      defaultCacheDuration: defaultCacheDuration ?? this.defaultCacheDuration,
      enableLogging: enableLogging ?? this.enableLogging,
      enableCaching: enableCaching ?? this.enableCaching,
      enableRetry: enableRetry ?? this.enableRetry,
      refreshTokenEndpoint: refreshTokenEndpoint ?? this.refreshTokenEndpoint,
    );
  }

  /// Default development configuration
  static NetworkConfig development({required String baseUrl}) {
    return NetworkConfig(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      enableLogging: true,
    );
  }

  /// Default production configuration
  static NetworkConfig production({required String baseUrl}) {
    return NetworkConfig(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      enableLogging: false,
    );
  }
}
