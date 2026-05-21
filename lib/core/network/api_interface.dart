import 'package:dio/dio.dart';

import 'models/api_response.dart';
import 'utils/typedefs.dart';

/// Abstract interface for API operations
///
/// Defines the contract for network operations that can be
/// implemented by different HTTP clients.
abstract class ApiInterface {
  const ApiInterface();

  /// GET request returning a list of objects
  Future<List<T>> getCollection<T>({
    required String endpoint,
    JSON? queryParams,
    CancelToken? cancelToken,
    required T Function(dynamic responseBody) converter,
  });

  /// GET request returning a single object
  Future<ApiResponse<T>> get<T>({
    required String endpoint,
    JSON? queryParams,
    CancelToken? cancelToken,
    required T Function(dynamic responseBody) converter,
  });

  /// POST request
  Future<ApiResponse<T>> post<T>({
    required String endpoint,
    required JSON data,
    CancelToken? cancelToken,
    required T Function(dynamic response) converter,
  });

  /// POST request with form data (multipart)
  Future<ApiResponse<T>> postFormData<T>({
    required String endpoint,
    required JSON data,
    List<MapEntry<String, MultipartFile>>? files,
    CancelToken? cancelToken,
    required T Function(dynamic response) converter,
  });

  /// PUT request
  Future<ApiResponse<T>> put<T>({
    required String endpoint,
    required JSON data,
    CancelToken? cancelToken,
    required T Function(dynamic response) converter,
  });

  /// PATCH request
  Future<ApiResponse<T>> patch<T>({
    required String endpoint,
    required JSON data,
    CancelToken? cancelToken,
    required T Function(dynamic response) converter,
  });

  /// DELETE request
  Future<ApiResponse<T>> delete<T>({
    required String endpoint,
    JSON? data,
    CancelToken? cancelToken,
    required T Function(dynamic response) converter,
  });

  /// Cancels pending requests
  void cancelRequests({CancelToken? cancelToken});
}
