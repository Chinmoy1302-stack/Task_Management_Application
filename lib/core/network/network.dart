/// Modular Network Layer for Flutter Base Project
///
/// This library provides a complete, reusable network layer with:
/// - Dio HTTP client with configurable interceptors
/// - Smart retry on network failures
/// - Request/Response caching
/// - Cancel token management per feature/screen
/// - Standardized error handling
///
/// Usage:
/// ```dart
/// import 'package:dio/dio.dart';
/// import 'package:flutter/foundation.dart';
/// import 'package:flutter_base_project/core/network/network.dart';
///
/// final api = DioNetwork();
/// final token = CancelTokenManager().createToken('my_feature');
///
/// final response = await api.get(
///   endpoint: '/users',
///   cancelToken: token,
///   converter: (json) => User.fromJson(json),
/// );
/// ```
library;

// Configuration
export 'config/network_config.dart';

// Client
export 'client/dio_client.dart';

// Interceptors
export 'interceptors/auth_interceptor.dart';
export 'interceptors/logging_interceptor.dart';
export 'interceptors/cache_interceptor.dart';
export 'interceptors/retry_interceptor.dart';

// Services
export 'services/dio_service.dart';
export 'services/dio_network.dart';

// Models
export 'models/api_response.dart';
export 'models/api_exception.dart';

// Cancel Token
export 'cancel_token_manager.dart';

// Utilities
export 'utils/typedefs.dart';

// Interface
export 'api_interface.dart';
