import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor that handles authentication token injection and refresh.
///
/// **Features:**
/// - Automatically adds Bearer token to requests
/// - Handles 401 responses with token refresh
/// - Queues requests while refreshing to prevent multiple refresh calls
/// - Retries failed requests after successful refresh
class AuthInterceptor extends Interceptor {
  /// Function to get the current access token
  final String? Function() tokenProvider;

  /// Function to handle token refresh
  /// Should return a map with 'accessToken' and optionally 'refreshToken'
  final Future<Map<String, String>?> Function()? refreshTokenHandler;

  /// Callback when token refresh fails
  final VoidCallback? onRefreshFailed;

  /// Queue of requests waiting for token refresh
  final List<_QueuedRequest> _requestQueue = [];

  /// Completer for managing concurrent refresh requests
  Completer<void>? _refreshCompleter;

  AuthInterceptor({
    required this.tokenProvider,
    this.refreshTokenHandler,
    this.onRefreshFailed,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Skip if already has authorization header
    if (options.headers.containsKey(HttpHeaders.authorizationHeader)) {
      return handler.next(options);
    }

    final token = tokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only handle 401 errors
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // If no refresh handler, just forward the error
    if (refreshTokenHandler == null) {
      return handler.next(err);
    }

    // Queue this request for retry after refresh
    final completer = Completer<Response>();
    _requestQueue.add(
      _QueuedRequest(requestOptions: err.requestOptions, completer: completer),
    );

    // If not already refreshing, start refresh
    if (_refreshCompleter == null) {
      _refreshCompleter = Completer<void>();
      await _refreshToken();
    } else {
      // Wait for ongoing refresh
      await _refreshCompleter!.future;
    }

    try {
      final response = await completer.future;
      handler.resolve(response);
    } catch (e) {
      handler.reject(err);
    }
  }

  Future<void> _refreshToken() async {
    try {
      final tokens = await refreshTokenHandler!();

      if (tokens == null || tokens['accessToken'] == null) {
        throw Exception('Token refresh returned null');
      }

      final newAccessToken = tokens['accessToken']!;

      // Retry all queued requests with new token
      for (final queued in _requestQueue) {
        try {
          final options = queued.requestOptions;
          options.headers[HttpHeaders.authorizationHeader] =
              'Bearer $newAccessToken';

          // Handle FormData cloning
          dynamic requestData = options.data;
          if (options.data is FormData) {
            requestData = _cloneFormData(options.data as FormData);
          }

          final response = await Dio().request(
            options.path,
            data: requestData,
            queryParameters: options.queryParameters,
            options: Options(
              method: options.method,
              headers: options.headers,
              responseType: options.responseType,
              contentType: options.contentType,
            ),
          );

          queued.completer.complete(response);
        } catch (e) {
          queued.completer.completeError(e);
        }
      }
    } catch (e) {
      // Notify all queued requests of failure
      for (final queued in _requestQueue) {
        queued.completer.completeError(e);
      }

      // Call failure callback
      onRefreshFailed?.call();
    } finally {
      _requestQueue.clear();
      _refreshCompleter?.complete();
      _refreshCompleter = null;
    }
  }

  FormData _cloneFormData(FormData original) {
    final newFormData = FormData();
    newFormData.fields.addAll(original.fields);

    for (final fileEntry in original.files) {
      newFormData.files.add(MapEntry(fileEntry.key, fileEntry.value.clone()));
    }

    return newFormData;
  }
}

class _QueuedRequest {
  final RequestOptions requestOptions;
  final Completer<Response> completer;

  _QueuedRequest({required this.requestOptions, required this.completer});
}
