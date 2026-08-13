import 'package:cinmovies_app/core/error/app_error.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabaseAuthErrorMapper implements ErrorMappingRule {
  const SupabaseAuthErrorMapper();

  @override
  AppError? tryMap(Object exception) {
    if (exception is! AuthException) return null;

    final code = exception.code;
    final message = exception.message.toLowerCase();
    if (code == 'invalid_credentials' ||
        code == 'bad_jwt' ||
        message.contains('invalid login credentials')) {
      return const AuthenticationAppError(
        message: 'The email or password is incorrect.',
      );
    }
    if (code == 'email_not_confirmed' ||
        code == 'email_not_verified' ||
        message.contains('email not confirmed')) {
      return const AuthenticationAppError(
        message: 'Please confirm your email address before signing in.',
      );
    }
    if (code == 'weak_password' || exception is AuthWeakPasswordException) {
      return const ValidationAppError(
        message: 'Please choose a stronger password.',
      );
    }
    if (code == 'user_already_exists' ||
        code == 'email_exists' ||
        message.contains('already registered')) {
      return const ValidationAppError(
        message: 'An account already exists for this email address.',
      );
    }
    if (code == 'over_request_rate_limit' ||
        code == 'too_many_requests' ||
        message.contains('rate limit')) {
      return const AuthenticationAppError(
        message: 'Too many attempts. Please wait a moment and try again.',
      );
    }
    if (code == 'signup_disabled') {
      return const AuthenticationAppError(
        message: 'Sign up is not available right now.',
      );
    }
    if (code == 'otp_expired' || message.contains('token has expired')) {
      return const AuthenticationAppError(
        message:
            'This verification code has expired. Please request a new one.',
      );
    }
    if (code == 'reauthentication_needed') {
      return const AuthenticationAppError(
        message: 'Please sign in again to continue.',
      );
    }
    if (code == 'provider_disabled') {
      return const AuthenticationAppError(
        message: 'This sign-in method is not available right now.',
      );
    }
    if (exception.statusCode == '401' || exception.statusCode == '403') {
      return const AuthenticationAppError(
        message: 'Your session has expired. Please sign in again.',
      );
    }
    return const AuthenticationAppError(
      message: 'We could not complete authentication. Please try again.',
    );
  }
}
