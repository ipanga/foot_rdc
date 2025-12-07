import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/core/constants/api_constants.dart';
import 'package:foot_rdc/core/network/network_exceptions.dart';

/// Dio client provider for the entire application
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

/// Centralized Dio HTTP client with interceptors and error handling
class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(_baseOptions);
    _setupInterceptors();
  }

  /// Base configuration for all requests
  BaseOptions get _baseOptions => BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      );

  /// Setup interceptors for logging and error handling
  void _setupInterceptors() {
    // Logging interceptor (only in debug mode)
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint('DIO: $obj'),
      ));
    }

    // Retry interceptor for transient failures
    _dio.interceptors.add(_RetryInterceptor(_dio));
  }

  /// Get the underlying Dio instance (for advanced use cases)
  Dio get dio => _dio;

  /// Perform a GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  /// Perform a POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  /// Perform a PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }

  /// Perform a DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } catch (e) {
      throw NetworkExceptionHandler.handle(e);
    }
  }
}

/// Retry interceptor for handling transient failures
class _RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int _maxRetries;
  final Duration _retryDelay;

  _RetryInterceptor(
    this._dio, {
    int maxRetries = 2,
    Duration retryDelay = const Duration(seconds: 1),
  })  : _maxRetries = maxRetries,
        _retryDelay = retryDelay;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only retry on connection errors or timeouts
    if (_shouldRetry(err)) {
      final retries = err.requestOptions.extra['retries'] as int? ?? 0;

      if (retries < _maxRetries) {
        if (kDebugMode) {
          debugPrint('DIO: Retrying request (${retries + 1}/$_maxRetries)');
        }

        await Future.delayed(_retryDelay);

        try {
          err.requestOptions.extra['retries'] = retries + 1;
          final response = await _dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } catch (e) {
          // If retry fails, continue with the error
        }
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}
