import 'package:cinmovies_app/core/error/app_error.dart';
import 'package:cinmovies_app/core/error/default_error_mapper.dart';
import 'package:cinmovies_app/core/error/exceptions.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const mapper = DefaultErrorMapper();

  test('maps connection errors to a useful network message', () {
    final failure = mapper.map(
      DioException(
        requestOptions: RequestOptions(path: '/movies'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(failure, isA<NetworkAppError>());
    expect(failure.message, contains('internet connection'));
  });

  test('maps common service errors without exposing raw details', () {
    expect(
      mapper
          .map(const AuthException('bad login', code: 'invalid_credentials'))
          .message,
      'The email or password is incorrect.',
    );
    expect(
      mapper
          .map(
            const PostgrestException(
              message: 'duplicate key value',
              code: '23505',
            ),
          )
          .message,
      'This item already exists.',
    );
    expect(
      mapper
          .map(const StorageException('payload too large', statusCode: '413'))
          .message,
      'This file is too large to upload.',
    );
  });

  test('preserves intentional server messages and hides unknown errors', () {
    expect(
      mapper.map(const ServerException(message: 'Assistant is busy.')).message,
      'Assistant is busy.',
    );
    expect(
      mapper.map(StateError('database password leaked')).message,
      'Something went wrong. Please try again.',
    );
  });
}
