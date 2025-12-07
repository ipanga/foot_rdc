import 'dart:io';
import 'package:dio/dio.dart';

/// Base class for all network-related exceptions
sealed class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const NetworkException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// No internet connection
class NoInternetException extends NetworkException {
  const NoInternetException({
    super.message = 'Pas de connexion internet',
    super.originalError,
  });
}

/// Request timeout
class TimeoutException extends NetworkException {
  const TimeoutException({
    super.message = 'La requete a expire',
    super.originalError,
  });
}

/// Server error (5xx)
class ServerException extends NetworkException {
  const ServerException({
    super.message = 'Erreur serveur',
    super.statusCode,
    super.originalError,
  });
}

/// Client error (4xx)
class ClientException extends NetworkException {
  const ClientException({
    super.message = 'Erreur de requete',
    super.statusCode,
    super.originalError,
  });
}

/// Not found error (404)
class NotFoundException extends NetworkException {
  const NotFoundException({
    super.message = 'Ressource non trouvee',
    super.statusCode = 404,
    super.originalError,
  });
}

/// Unauthorized error (401)
class UnauthorizedException extends NetworkException {
  const UnauthorizedException({
    super.message = 'Non autorise',
    super.statusCode = 401,
    super.originalError,
  });
}

/// Unknown/unexpected error
class UnknownException extends NetworkException {
  const UnknownException({
    super.message = 'Une erreur inattendue est survenue',
    super.originalError,
  });
}

/// Request cancelled
class RequestCancelledException extends NetworkException {
  const RequestCancelledException({
    super.message = 'Requete annulee',
    super.originalError,
  });
}

/// Helper class to handle and convert DioExceptions to NetworkExceptions
class NetworkExceptionHandler {
  static NetworkException handle(dynamic error) {
    if (error is DioException) {
      return _handleDioException(error);
    } else if (error is SocketException) {
      return NoInternetException(originalError: error);
    } else if (error is NetworkException) {
      return error;
    } else {
      return UnknownException(
        message: error.toString(),
        originalError: error,
      );
    }
  }

  static NetworkException _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(originalError: error);

      case DioExceptionType.connectionError:
        return NoInternetException(originalError: error);

      case DioExceptionType.cancel:
        return RequestCancelledException(originalError: error);

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.badCertificate:
        return const ServerException(message: 'Certificat invalide');

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return NoInternetException(originalError: error);
        }
        return UnknownException(originalError: error);
    }
  }

  static NetworkException _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    String? serverMessage;
    if (responseData is Map<String, dynamic>) {
      serverMessage = responseData['message'] as String? ??
          responseData['error'] as String?;
    }

    switch (statusCode) {
      case 400:
        return ClientException(
          message: serverMessage ?? 'Requete invalide',
          statusCode: statusCode,
          originalError: error,
        );
      case 401:
        return UnauthorizedException(
          message: serverMessage ?? 'Non autorise',
          originalError: error,
        );
      case 403:
        return ClientException(
          message: serverMessage ?? 'Acces refuse',
          statusCode: statusCode,
          originalError: error,
        );
      case 404:
        return NotFoundException(
          message: serverMessage ?? 'Ressource non trouvee',
          originalError: error,
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(
          message: serverMessage ?? 'Erreur serveur',
          statusCode: statusCode,
          originalError: error,
        );
      default:
        if (statusCode != null && statusCode >= 400 && statusCode < 500) {
          return ClientException(
            message: serverMessage ?? 'Erreur client',
            statusCode: statusCode,
            originalError: error,
          );
        }
        return ServerException(
          message: serverMessage ?? 'Erreur serveur',
          statusCode: statusCode,
          originalError: error,
        );
    }
  }
}
