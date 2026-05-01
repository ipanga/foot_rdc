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

/// Retry interceptor for transient connection failures.
///
/// Strategy: exponential backoff with a hard cap on attempts. Delay between
/// retry N and N+1 is `_baseDelay * 2^N` (i.e. 1s, 2s, 4s for the default
/// base of 1s). Total wait before final failure: ~7s — enough to ride out
/// short network blips without making the user wait too long when the
/// network is genuinely down.
///
/// Only fires on connection-layer errors (connection/receive timeout,
/// connection error). 4xx and 5xx responses are NOT retried — they go
/// straight to [NetworkExceptionHandler].
class _RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int _maxRetries;
  final Duration _baseDelay;

  _RetryInterceptor(
    this._dio, {
    int maxRetries = 3,
    Duration baseDelay = const Duration(seconds: 1),
  })  : _maxRetries = maxRetries,
        _baseDelay = baseDelay;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      final retries = err.requestOptions.extra['retries'] as int? ?? 0;

      if (retries < _maxRetries) {
        final delay = _baseDelay * (1 << retries); // 1s, 2s, 4s ...

        if (kDebugMode) {
          debugPrint(
              'DIO: Retrying request (${retries + 1}/$_maxRetries) after ${delay.inMilliseconds}ms');
        }

        await Future.delayed(delay);

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
