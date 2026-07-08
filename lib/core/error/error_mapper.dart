import 'package:cinmovies_app/core/error/exceptions.dart';
import 'package:cinmovies_app/core/error/failures.dart';
import 'package:dio/dio.dart';

Failure mapExceptionToFailure(Object exception) {
  if (exception is ServerException) {
    return ServerFailure(
      message: exception.message,
      statusCode: exception.statusCode,
    );
  }

  if (exception is CacheException) {
    return CacheFailure(message: exception.message);
  }

  if (exception is NetworkException) {
    return NetworkFailure(message: exception.message);
  }

  if (exception is DioException) {
    return ServerFailure(
      message: exception.message ?? 'Something went wrong',
      statusCode: exception.response?.statusCode,
    );
  }

  return UnknownFailure(message: exception.toString());
}
