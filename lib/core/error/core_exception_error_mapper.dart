import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/exceptions.dart';
import 'package:cinmovies_app/core/error/failures.dart';

class CoreExceptionErrorMapper implements ErrorMapper {
  const CoreExceptionErrorMapper();

  @override
  Failure? tryMap(Object exception) {
    return switch (exception) {
      ServerException() => ServerFailure(
        message: exception.message,
        statusCode: exception.statusCode,
      ),
      CacheException() => CacheFailure(message: exception.message),
      NetworkException() => NetworkFailure(message: exception.message),
      _ => null,
    };
  }
}
