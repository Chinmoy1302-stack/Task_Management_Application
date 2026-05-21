// Re-export RetryInterceptor from dio_smart_retry for convenience
export 'package:dio_smart_retry/dio_smart_retry.dart';

/// Retry configuration helper
///
/// Usage:
/// ```dart
/// RetryInterceptor(
///   dio: dio,
///   retries: 3,
///   retryDelays: defaultRetryDelays,
/// )
/// ```

/// Default retry delays with exponential backoff
const List<Duration> defaultRetryDelays = [
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 4),
];

/// Short retry delays for quick retries
const List<Duration> shortRetryDelays = [
  Duration(milliseconds: 500),
  Duration(seconds: 1),
  Duration(seconds: 2),
];

/// Long retry delays for important requests
const List<Duration> longRetryDelays = [
  Duration(seconds: 2),
  Duration(seconds: 5),
  Duration(seconds: 10),
];
