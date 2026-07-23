import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/failures.dart';
import 'package:dio/dio.dart';

class DioErrorMapper implements ErrorMapper {
  const DioErrorMapper();

  @override
  Failure? tryMap(Object exception) {
    if (exception is! DioException) return null;

    if (_isConnectivityIssue(exception.type)) {
      return const NetworkFailure(
        message: 'Please check your internet connection and try again.',
      );
    }

    return ServerFailure(
      message: _messageForStatusCode(exception.response?.statusCode),
      statusCode: exception.response?.statusCode,
    );
  }

  bool _isConnectivityIssue(DioExceptionType type) => switch (type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout => true,
    _ => false,
  };

  String _messageForStatusCode(int? code) => switch (code) {
    400 => 'Please check the information and try again.',
    401 || 403 => 'You do not have permission to do that.',
    404 => 'We could not find the requested data.',
    408 => 'The request timed out. Please try again.',
    409 => 'This action conflicts with existing data.',
    429 => 'Too many attempts. Please wait a moment and try again.',
    500 || 502 || 503 || 504 =>
      'The service is temporarily unavailable. Please try again.',
    _ => 'Something went wrong. Please try again.',
  };
}
