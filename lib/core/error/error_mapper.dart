import 'package:cinmovies_app/core/error/failures.dart';

abstract interface class ErrorMapper {
  Failure? tryMap(Object exception);
}

class ErrorMapperRegistry implements ErrorMapper {
  const ErrorMapperRegistry(this._mappers);

  final List<ErrorMapper> _mappers;

  @override
  Failure? tryMap(Object exception) {
    for (final mapper in _mappers) {
      final failure = mapper.tryMap(exception);
      if (failure != null) return failure;
    }
    return null;
  }

  Failure map(Object exception) =>
      tryMap(exception) ??
      const UnknownFailure(message: 'Something went wrong. Please try again.');
}
