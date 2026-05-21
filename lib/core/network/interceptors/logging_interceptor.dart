import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// Interceptor for logging HTTP requests and responses.
///
/// Only logs in debug mode. Provides detailed information about:
/// - Request method, URL, headers, and body
/// - Response status, headers, and body
/// - Error details
class LoggingInterceptor extends Interceptor {
  /// Whether to log request headers
  final bool logHeaders;

  /// Whether to log request/response body
  final bool logBody;

  /// Maximum length of body to log (to prevent huge logs)
  final int maxBodyLength;

  const LoggingInterceptor({
    this.logHeaders = true,
    this.logBody = true,
    this.maxBodyLength = 1000,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final buffer = StringBuffer();
    buffer.writeln(
      '╔══════════════════════════════════════════════════════════',
    );
    buffer.writeln('║ 📤 REQUEST');
    buffer.writeln(
      '╠══════════════════════════════════════════════════════════',
    );
    buffer.writeln('║ ${options.method} ${options.uri}');

    if (logHeaders && options.headers.isNotEmpty) {
      buffer.writeln('║ Headers:');
      options.headers.forEach((key, value) {
        // Mask sensitive headers
        final displayValue = _shouldMask(key) ? '***' : value;
        buffer.writeln('║   $key: $displayValue');
      });
    }

    if (logBody && options.data != null) {
      buffer.writeln('║ Body:');
      final body = _formatBody(options.data);
      buffer.writeln('║   $body');
    }

    buffer.writeln(
      '╚══════════════════════════════════════════════════════════',
    );

    developer.log(buffer.toString(), name: 'HTTP');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final buffer = StringBuffer();
    buffer.writeln(
      '╔══════════════════════════════════════════════════════════',
    );
    buffer.writeln('║ 📥 RESPONSE [${response.statusCode}]');
    buffer.writeln(
      '╠══════════════════════════════════════════════════════════',
    );
    buffer.writeln(
      '║ ${response.requestOptions.method} ${response.requestOptions.uri}',
    );

    if (logBody && response.data != null) {
      buffer.writeln('║ Body:');
      final body = _formatBody(response.data);
      buffer.writeln('║   $body');
    }

    buffer.writeln(
      '╚══════════════════════════════════════════════════════════',
    );

    developer.log(buffer.toString(), name: 'HTTP');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final buffer = StringBuffer();
    buffer.writeln(
      '╔══════════════════════════════════════════════════════════',
    );
    buffer.writeln('║ ❌ ERROR [${err.response?.statusCode ?? err.type}]');
    buffer.writeln(
      '╠══════════════════════════════════════════════════════════',
    );
    buffer.writeln('║ ${err.requestOptions.method} ${err.requestOptions.uri}');
    buffer.writeln('║ Message: ${err.message}');

    if (err.response?.data != null) {
      buffer.writeln('║ Response:');
      final body = _formatBody(err.response?.data);
      buffer.writeln('║   $body');
    }

    buffer.writeln(
      '╚══════════════════════════════════════════════════════════',
    );

    developer.log(buffer.toString(), name: 'HTTP');
    handler.next(err);
  }

  bool _shouldMask(String headerName) {
    final lowerName = headerName.toLowerCase();
    return lowerName == 'authorization' ||
        lowerName == 'cookie' ||
        lowerName == 'x-api-key';
  }

  String _formatBody(dynamic data) {
    try {
      if (data is Map || data is List) {
        final encoded = const JsonEncoder.withIndent('  ').convert(data);
        if (encoded.length > maxBodyLength) {
          return '${encoded.substring(0, maxBodyLength)}... [truncated]';
        }
        return encoded;
      } else if (data is FormData) {
        return 'FormData: ${data.fields.map((e) => '${e.key}=${e.value}').join(', ')}';
      } else {
        final str = data.toString();
        if (str.length > maxBodyLength) {
          return '${str.substring(0, maxBodyLength)}... [truncated]';
        }
        return str;
      }
    } catch (e) {
      return data.toString();
    }
  }
}
