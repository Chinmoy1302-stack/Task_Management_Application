import 'dart:io';

import 'package:dio/dio.dart';

/// Custom exception for API errors
///
/// Provides structured error information with user-friendly messages.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errorData;
  final DioExceptionType? type;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errorData,
    this.type,
  });

  /// Creates an ApiException from a DioException
  factory ApiException.fromDioError(DioException e) {
    // Handle timeout errors
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        message: 'Connection timed out. Please try again.',
        statusCode: 408,
        type: e.type,
      );
    }

    // Handle connection errors
    if (e.type == DioExceptionType.connectionError ||
        e.error is SocketException) {
      return ApiException(
        message: 'No internet connection. Please check your network.',
        statusCode: 503,
        type: e.type,
      );
    }

    // Handle cancelled requests
    if (e.type == DioExceptionType.cancel) {
      return ApiException(
        message: 'Request was cancelled.',
        statusCode: 499,
        type: e.type,
      );
    }

    // Handle server response errors
    if (e.response != null) {
      final status = e.response?.statusCode;
      final errorBody = e.response?.data;
      String errorMsg = 'Something went wrong. Please try again.';

      if (errorBody is Map && errorBody['message'] != null) {
        errorMsg = errorBody['message'].toString();
      } else if (errorBody is String && errorBody.isNotEmpty) {
        errorMsg = errorBody;
      } else {
        // Default messages based on status code
        errorMsg = _getMessageForStatusCode(status);
      }

      return ApiException(
        message: errorMsg,
        statusCode: status,
        errorData: errorBody,
        type: e.type,
      );
    }

    // Fallback
    return ApiException(
      message: e.message ?? 'Unexpected error occurred',
      statusCode: 500,
      type: e.type,
    );
  }

  static String _getMessageForStatusCode(int? code) {
    switch (code) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Access denied.';
      case 404:
        return 'Resource not found.';
      case 409:
        return 'Conflict. Resource already exists.';
      case 422:
        return 'Validation error.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Bad gateway. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  String toString() => 'ApiException: $message (code: $statusCode)';

  /// Whether this error is due to lack of network
  bool get isNetworkError =>
      type == DioExceptionType.connectionError ||
      type == DioExceptionType.connectionTimeout;

  /// Whether this error is due to timeout
  bool get isTimeoutError =>
      type == DioExceptionType.connectionTimeout ||
      type == DioExceptionType.sendTimeout ||
      type == DioExceptionType.receiveTimeout;

  /// Whether this error is due to cancellation
  bool get isCancelledError => type == DioExceptionType.cancel;

  /// Whether this is a server error (5xx)
  bool get isServerError => (statusCode ?? 0) >= 500;

  /// Whether this is a client error (4xx)
  bool get isClientError => (statusCode ?? 0) >= 400 && (statusCode ?? 0) < 500;

  /// Whether this error should trigger a retry
  bool get isRetryable => isNetworkError || isTimeoutError || isServerError;
}
