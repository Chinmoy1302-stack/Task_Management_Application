import 'package:flutter/material.dart';

/// Status of an API response
enum ApiStatus { empty, loading, success, error }

/// Generic API response wrapper with status tracking
///
/// **Usage:**
/// ```dart
/// final response = await api.get(...);
/// response.when(
///   success: (data) => print(data),
///   error: (error) => print(error.message),
/// );
/// ```
class ApiResponse<T> {
  final ApiStatus status;
  final T? data;
  final ApiError? error;

  const ApiResponse._({required this.status, this.data, this.error});

  /// Creates an empty response
  factory ApiResponse.empty() => const ApiResponse._(status: ApiStatus.empty);

  /// Creates a loading response
  factory ApiResponse.loading() =>
      const ApiResponse._(status: ApiStatus.loading);

  /// Creates a success response with data
  factory ApiResponse.success(T data) =>
      ApiResponse._(status: ApiStatus.success, data: data);

  /// Creates an error response
  factory ApiResponse.error(ApiError error) =>
      ApiResponse._(status: ApiStatus.error, error: error);

  /// Creates an error response from code and message
  factory ApiResponse.errorFromMessage(String message, {int? code}) =>
      ApiResponse._(
        status: ApiStatus.error,
        error: ApiError(code: code ?? 0, message: message),
      );

  // Convenience getters
  bool get isEmpty => status == ApiStatus.empty;
  bool get isLoading => status == ApiStatus.loading;
  bool get isSuccess => status == ApiStatus.success;
  bool get isError => status == ApiStatus.error;

  /// Pattern matching for API response states
  R when<R>({
    R Function()? empty,
    R Function()? loading,
    required R Function(T data) success,
    R Function(ApiError error)? error,
  }) {
    switch (status) {
      case ApiStatus.empty:
        return empty?.call() ?? success(data as T);
      case ApiStatus.loading:
        return loading?.call() ?? success(data as T);
      case ApiStatus.success:
        return success(data as T);
      case ApiStatus.error:
        if (error != null) {
          return error(this.error!);
        }
        throw StateError('Error handler not provided for error state');
    }
  }

  /// Handle response states with callbacks
  void whenStatus({
    VoidCallback? empty,
    VoidCallback? loading,
    void Function(T data)? success,
    void Function(ApiError error)? error,
  }) {
    switch (status) {
      case ApiStatus.empty:
        empty?.call();
        break;
      case ApiStatus.loading:
        loading?.call();
        break;
      case ApiStatus.success:
        if (data != null) success?.call(data as T);
        break;
      case ApiStatus.error:
        if (this.error != null) error?.call(this.error!);
        break;
    }
  }

  /// Maps the data to a different type
  ApiResponse<R> map<R>(R Function(T data) mapper) {
    if (isSuccess && data != null) {
      return ApiResponse.success(mapper(data as T));
    } else if (isError) {
      return ApiResponse.error(error!);
    } else if (isLoading) {
      return ApiResponse.loading();
    }
    return ApiResponse.empty();
  }
}

/// Error response model
class ApiError {
  final int code;
  final String message;
  final dynamic data;

  const ApiError({required this.code, required this.message, this.data});

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] ?? 0,
      message: json['message'] ?? 'Unknown error',
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'message': message,
    'data': data,
  };

  @override
  String toString() => 'ApiError(code: $code, message: $message)';
}

/// Widget extension for ApiResponse
extension ApiResponseWidgetX<T> on ApiResponse<T> {
  Widget whenWidget({
    Widget Function()? empty,
    Widget Function()? loading,
    required Widget Function(T data) success,
    Widget Function(ApiError error)? error,
  }) {
    switch (status) {
      case ApiStatus.empty:
        return empty?.call() ?? const SizedBox.shrink();
      case ApiStatus.loading:
        return loading?.call() ??
            const Center(child: CircularProgressIndicator());
      case ApiStatus.success:
        return success(data as T);
      case ApiStatus.error:
        return error?.call(this.error!) ??
            Center(child: Text(this.error?.message ?? 'Error'));
    }
  }
}
