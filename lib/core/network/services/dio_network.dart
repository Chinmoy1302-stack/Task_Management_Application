import 'dart:developer';

import 'package:dio/dio.dart';

import '../api_interface.dart';
import '../client/dio_client.dart';
import '../models/api_exception.dart';
import '../models/api_response.dart';
import '../services/dio_service.dart';
import '../utils/typedefs.dart';

/// High-level network class implementing [ApiInterface]
///
/// Provides convenient methods for making API requests with:
/// - Automatic error handling
/// - Response conversion
/// - Cancel token support
///
/// **Usage:**
/// ```dart
/// final api = DioNetwork();
///
/// final response = await api.get(
///   endpoint: '/users/1',
///   converter: (json) => User.fromJson(json),
/// );
///
/// response.when(
///   success: (user) => print(user.name),
///   error: (e) => print(e.message),
/// );
/// ```
class DioNetwork implements ApiInterface {
  late final DioService _dioService;

  /// Creates a DioNetwork using the singleton DioClient
  DioNetwork() : _dioService = DioService(dioClient: DioClient.instance);

  /// Creates a DioNetwork with a custom Dio instance
  DioNetwork.withDio(Dio dio) : _dioService = DioService(dioClient: dio);

  // =========================================================================
  // GET METHODS
  // =========================================================================

  @override
  Future<List<T>> getCollection<T>({
    required String endpoint,
    JSON? queryParams,
    CancelToken? cancelToken,
    Options? options,
    required T Function(dynamic responseBody) converter,
  }) async {
    try {
      final response = await _dioService.get<List<dynamic>>(
        endpoint: endpoint,
        queryParams: queryParams,
        options: options,
        cancelToken: cancelToken,
      );

      return (response.data ?? []).map((e) => converter(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<ApiResponse<T>> get<T>({
    required String endpoint,
    JSON? queryParams,
    CancelToken? cancelToken,
    Options? options,
    required T Function(dynamic responseBody) converter,
  }) async {
    try {
      final response = await _dioService.get<dynamic>(
        endpoint: endpoint,
        queryParams: queryParams,
        options: options,
        cancelToken: cancelToken,
      );

      return ApiResponse.success(converter(response.data));
    } on DioException catch (e) {
      final exception = ApiException.fromDioError(e);
      return ApiResponse.error(
        ApiError(
          code: exception.statusCode ?? 500,
          message: exception.message,
          data: exception.errorData,
        ),
      );
    }
  }

  // =========================================================================
  // POST METHODS
  // =========================================================================

  @override
  Future<ApiResponse<T>> post<T>({
    required String endpoint,
    required JSON data,
    CancelToken? cancelToken,
    JSON? queryParams,
    Options? options,
    required T Function(dynamic responseBody) converter,
  }) async {
    try {
      final response = await _dioService.post<dynamic>(
        endpoint: endpoint,
        data: data,
        queryParams: queryParams,
        options: options,
        cancelToken: cancelToken,
      );

      return ApiResponse.success(converter(response.data));
    } on DioException catch (e) {
      final exception = ApiException.fromDioError(e);
      return ApiResponse.error(
        ApiError(
          code: exception.statusCode ?? 500,
          message: exception.message,
          data: exception.errorData,
        ),
      );
    }
  }

  /// POST with list response
  Future<ApiResponse<List<T>>> postCollection<T>({
    required String endpoint,
    required JSON data,
    JSON? queryParams,
    CancelToken? cancelToken,
    Options? options,
    required T Function(JSON responseBody) converter,
  }) async {
    try {
      final response = await _dioService.post<JSON>(
        endpoint: endpoint,
        data: data,
        options: options,
        cancelToken: cancelToken,
      );

      final rawList = response.data?['data'] as List?;
      final list =
          rawList?.map((e) => converter(e as Map<String, dynamic>)).toList() ??
          [];

      return ApiResponse.success(list);
    } on DioException catch (e) {
      final exception = ApiException.fromDioError(e);
      return ApiResponse.error(
        ApiError(
          code: exception.statusCode ?? 500,
          message: exception.message,
          data: exception.errorData,
        ),
      );
    }
  }

  @override
  Future<ApiResponse<T>> postFormData<T>({
    required String endpoint,
    required JSON data,
    List<MapEntry<String, MultipartFile>>? files,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    void Function(int, int)? onSendProgress,
    required T Function(dynamic) converter,
  }) async {
    try {
      final formData = FormData();

      // Add regular fields
      data.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });

      log('📝 Form fields: ${formData.fields}');

      // Add files if any
      if (files != null && files.isNotEmpty) {
        for (var file in files) {
          log('📎 Attaching file: ${file.value.filename}, key: ${file.key}');
          formData.files.add(file);
        }
      }

      final response = await _dioService.multipart<dynamic>(
        endpoint: endpoint,
        data: formData,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );

      return ApiResponse.success(converter(response.data));
    } on DioException catch (e) {
      final exception = ApiException.fromDioError(e);
      return ApiResponse.error(
        ApiError(
          code: exception.statusCode ?? 500,
          message: exception.message,
          data: exception.errorData,
        ),
      );
    }
  }

  // =========================================================================
  // PUT / PATCH METHODS
  // =========================================================================

  @override
  Future<ApiResponse<T>> put<T>({
    required String endpoint,
    required JSON data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    required T Function(dynamic response) converter,
  }) async {
    try {
      final response = await _dioService.put<dynamic>(
        endpoint: endpoint,
        data: data,
        options: options,
        cancelToken: cancelToken,
      );

      return ApiResponse.success(converter(response.data));
    } on DioException catch (e) {
      final exception = ApiException.fromDioError(e);
      return ApiResponse.error(
        ApiError(
          code: exception.statusCode ?? 500,
          message: exception.message,
          data: exception.errorData,
        ),
      );
    }
  }

  @override
  Future<ApiResponse<T>> patch<T>({
    required String endpoint,
    required JSON data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    required T Function(dynamic response) converter,
  }) async {
    try {
      final response = await _dioService.patch<dynamic>(
        endpoint: endpoint,
        data: data,
        options: options,
        cancelToken: cancelToken,
      );

      return ApiResponse.success(converter(response.data));
    } on DioException catch (e) {
      final exception = ApiException.fromDioError(e);
      return ApiResponse.error(
        ApiError(
          code: exception.statusCode ?? 500,
          message: exception.message,
          data: exception.errorData,
        ),
      );
    }
  }

  // =========================================================================
  // DELETE METHOD
  // =========================================================================

  @override
  Future<ApiResponse<T>> delete<T>({
    required String endpoint,
    JSON? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    required T Function(dynamic response) converter,
  }) async {
    try {
      final response = await _dioService.delete<dynamic>(
        endpoint: endpoint,
        data: data,
        queryParams: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      return ApiResponse.success(converter(response.data));
    } on DioException catch (e) {
      final exception = ApiException.fromDioError(e);
      return ApiResponse.error(
        ApiError(
          code: exception.statusCode ?? 500,
          message: exception.message,
          data: exception.errorData,
        ),
      );
    }
  }

  // =========================================================================
  // CANCEL REQUESTS
  // =========================================================================

  @override
  void cancelRequests({CancelToken? cancelToken}) {
    _dioService.cancelRequests(cancelToken: cancelToken);
  }
}
