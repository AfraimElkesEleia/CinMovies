import 'package:cinmovies_app/core/error/app_error.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:dio/dio.dart';

final class DioErrorMapper implements ErrorMappingRule {
  const DioErrorMapper();

  @override
  AppError? tryMap(Object exception) {
    if (exception is! DioException) return null;

    if (_isConnectivityFailure(exception.type)) {
      return const NetworkAppError(
        message: 'Please check your internet connection and try again.',
      );
    }

    final statusCode = exception.response?.statusCode;
    return switch (statusCode) {
      400 => const ValidationAppError(
        message: 'Please check the information and try again.',
      ),
      401 || 403 => const AuthenticationAppError(
        message: 'You do not have permission to do that.',
      ),
      409 => const ValidationAppError(
        message: 'This action conflicts with existing data.',
      ),
      404 => const ServerAppError(
        message: 'We could not find the requested data.',
      ),
      408 => const NetworkAppError(
        message: 'The request timed out. Please try again.',
      ),
      429 => const ServerAppError(
        message: 'Too many attempts. Please wait a moment and try again.',
      ),
      500 || 502 || 503 || 504 => const ServerAppError(
        message: 'The service is temporarily unavailable. Please try again.',
      ),
      _ => const ServerAppError(
        message: 'Something went wrong. Please try again.',
      ),
    };
  }

  bool _isConnectivityFailure(DioExceptionType type) => switch (type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout => true,
    _ => false,
  };
}
