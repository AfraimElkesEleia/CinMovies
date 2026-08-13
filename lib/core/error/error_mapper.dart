import 'package:cinmovies_app/core/error/app_error.dart';

abstract interface class ErrorMapper {
  AppError map(Object exception);
}

abstract interface class ErrorMappingRule {
  AppError? tryMap(Object exception);
}

class ErrorMapperRegistry implements ErrorMapper {
  const ErrorMapperRegistry(this._rules);

  final List<ErrorMappingRule> _rules;

  @override
  AppError map(Object exception) {
    for (final rule in _rules) {
      final mapped = rule.tryMap(exception);
      if (mapped != null) return mapped;
    }
    return const UnknownAppError(
      message: 'Something went wrong. Please try again.',
    );
  }
}
