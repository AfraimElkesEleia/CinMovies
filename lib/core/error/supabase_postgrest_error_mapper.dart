import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePostgrestErrorMapper implements ErrorMapper {
  const SupabasePostgrestErrorMapper();

  @override
  Failure? tryMap(Object exception) {
    if (exception is! PostgrestException) return null;
    return _mapPostgrest(exception);
  }

  DatabaseFailure _mapPostgrest(PostgrestException exception) {
    final code = exception.code;
    final message = exception.message.toLowerCase();

    switch (code) {
      case '23505':
        return const DatabaseFailure(
          type: DatabaseFailureType.uniqueViolation,
          message: 'This item already exists.',
        );
      case '23503':
        return const DatabaseFailure(
          type: DatabaseFailureType.foreignKeyViolation,
          message: 'This action references data that no longer exists.',
        );
      case '42501':
        return const DatabaseFailure(
          type: DatabaseFailureType.permissionDenied,
          message: 'You do not have permission to do that.',
        );
      case 'PGRST116':
        return const DatabaseFailure(
          type: DatabaseFailureType.notFound,
          message: 'We could not find the requested data.',
        );
      case '22P02':
      case '23502':
      case '23514':
        return const DatabaseFailure(
          type: DatabaseFailureType.invalidInput,
          message: 'Please check the information and try again.',
        );
      case 'PGRST000':
      case 'PGRST001':
      case 'PGRST002':
      case 'PGRST003':
        return const DatabaseFailure(
          type: DatabaseFailureType.unavailable,
          message: 'The service is temporarily unavailable. Please try again.',
        );
    }

    if (message.contains('permission denied') ||
        message.contains('row-level security')) {
      return const DatabaseFailure(
        type: DatabaseFailureType.permissionDenied,
        message: 'You do not have permission to do that.',
      );
    }

    return const DatabaseFailure(
      type: DatabaseFailureType.unknown,
      message: 'We could not save your changes. Please try again.',
    );
  }
}
