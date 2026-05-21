import 'package:dio/dio.dart';

import '../models/api_response.dart';
import '../utils/typedefs.dart';

/// Low-level service wrapper around Dio
///
/// Provides typed request methods with cancel token support.
class DioService {
  final Dio _dio;
  final CancelToken _defaultCancelToken;

  DioService({required Dio dioClient})
    : _dio = dioClient,
      _defaultCancelToken = CancelToken();

  /// The underlying Dio instance
  Dio get dio => _dio;

  /// Cancels all requests using the default cancel token
  void cancelRequests({CancelToken? cancelToken, String? reason}) {
    final token = cancelToken ?? _defaultCancelToken;
    if (!token.isCancelled) {
      token.cancel(reason ?? 'Request cancelled');
    }
  }

  /// GET request
  Future<ApiResponse<T>> get<T>({
    required String endpoint,
    JSON? queryParams,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<T>(
      endpoint,
      queryParameters: queryParams,
      options: options,
      cancelToken: cancelToken ?? _defaultCancelToken,
    );
    return ApiResponse.success(response.data as T);
  }

  /// POST request
  Future<ApiResponse<T>> post<T>({
    required String endpoint,
    JSON? data,
    JSON? queryParams,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.post<T>(
      endpoint,
      data: data,
      queryParameters: queryParams,
      options: options,
      cancelToken: cancelToken ?? _defaultCancelToken,
    );
    return ApiResponse.success(response.data as T);
  }

  /// POST with FormData (multipart)
  Future<ApiResponse<T>> multipart<T>({
    required String endpoint,
    FormData? data,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
  }) async {
    final response = await _dio.post<T>(
      endpoint,
      data: data,
      options: options,
      cancelToken: cancelToken ?? _defaultCancelToken,
      onSendProgress: onSendProgress,
    );
    return ApiResponse.success(response.data as T);
  }

  /// PUT request
  Future<ApiResponse<T>> put<T>({
    required String endpoint,
    JSON? data,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.put<T>(
      endpoint,
      data: data,
      options: options,
      cancelToken: cancelToken ?? _defaultCancelToken,
    );
    return ApiResponse.success(response.data as T);
  }

  /// PATCH request
  Future<ApiResponse<T>> patch<T>({
    required String endpoint,
    JSON? data,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.patch<T>(
      endpoint,
      data: data,
      options: options,
      cancelToken: cancelToken ?? _defaultCancelToken,
    );
    return ApiResponse.success(response.data as T);
  }

  /// DELETE request
  Future<ApiResponse<T>> delete<T>({
    required String endpoint,
    JSON? data,
    JSON? queryParams,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.delete<T>(
      endpoint,
      data: data,
      queryParameters: queryParams,
      options: options,
      cancelToken: cancelToken ?? _defaultCancelToken,
    );
    return ApiResponse.success(response.data as T);
  }
}
