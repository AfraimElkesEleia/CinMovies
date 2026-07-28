import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/exceptions.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('maps connection errors to a useful network message', () {
    final failure = mapError(
      DioException(
        requestOptions: RequestOptions(path: '/movies'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(failure.message, contains('internet connection'));
  });

  test('maps common service errors without exposing raw details', () {
    expect(
      mapError(const AuthException('bad login', code: 'invalid_credentials'))
          .message,
      'The email or password is incorrect.',
    );
    expect(
      mapError(
        const PostgrestException(
          message: 'duplicate key value',
          code: '23505',
        ),
      ).message,
      'This item already exists.',
    );
    expect(
      mapError(
        const StorageException('payload too large', statusCode: '413'),
      ).message,
      'This file is too large to upload.',
    );
  });

  test('preserves intentional server messages and hides unknown errors', () {
    expect(
      mapError(const ServerException(message: 'Assistant is busy.')).message,
      'Assistant is busy.',
    );
    expect(
      mapError(StateError('database password leaked')).message,
      'Something went wrong. Please try again.',
    );
  });
}
