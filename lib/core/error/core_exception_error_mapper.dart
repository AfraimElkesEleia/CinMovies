import 'package:cinmovies_app/core/error/app_error.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/exceptions.dart';

final class CoreExceptionErrorMapper implements ErrorMappingRule {
  const CoreExceptionErrorMapper();

  @override
  AppError? tryMap(Object exception) {
    return switch (exception) {
      AuthenticationRequiredException() => AuthenticationAppError(
        message: exception.message,
      ),
      ValidationException() => ValidationAppError(message: exception.message),
      ServerException() => ServerAppError(message: exception.message),
      FormatException() => const ServerAppError(
        message: 'The service returned invalid data. Please try again.',
      ),
      _ => null,
    };
  }
}
