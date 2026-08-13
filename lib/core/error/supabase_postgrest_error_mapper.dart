import 'package:cinmovies_app/core/error/app_error.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabasePostgrestErrorMapper implements ErrorMappingRule {
  const SupabasePostgrestErrorMapper();

  @override
  AppError? tryMap(Object exception) {
    if (exception is! PostgrestException) return null;

    final message = exception.message.toLowerCase();
    return switch (exception.code) {
      '23505' => const DatabaseAppError(message: 'This item already exists.'),
      '23503' => const DatabaseAppError(
        message: 'This action references data that no longer exists.',
      ),
      '42501' => const DatabaseAppError(
        message: 'You do not have permission to do that.',
      ),
      'PGRST116' => const DatabaseAppError(
        message: 'We could not find the requested data.',
      ),
      '22P02' || '23502' || '23514' => const DatabaseAppError(
        message: 'Please check the information and try again.',
      ),
      'PGRST000' ||
      'PGRST001' ||
      'PGRST002' ||
      'PGRST003' => const DatabaseAppError(
        message: 'The service is temporarily unavailable. Please try again.',
      ),
      _
          when message.contains('permission denied') ||
              message.contains('row-level security') =>
        const DatabaseAppError(
          message: 'You do not have permission to do that.',
        ),
      _ => const DatabaseAppError(
        message: 'We could not save your changes. Please try again.',
      ),
    };
  }
}
