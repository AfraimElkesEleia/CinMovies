import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthErrorMapper implements ErrorMapper {
  const SupabaseAuthErrorMapper();

  @override
  Failure? tryMap(Object exception) {
    if (exception is! AuthException) return null;
    return _mapAuth(exception);
  }

  AuthFailure _mapAuth(AuthException exception) {
    final code = exception.code;
    final message = exception.message.toLowerCase();

    if (_hasCodeOrMessage(
      code: code,
      message: message,
      codes: const ['invalid_credentials', 'bad_jwt'],
      fragments: const ['invalid login credentials'],
    )) {
      return const AuthFailure(
        type: AuthFailureType.invalidCredentials,
        message: 'The email or password is incorrect.',
      );
    }

    if (_hasCodeOrMessage(
      code: code,
      message: message,
      codes: const ['email_not_confirmed', 'email_not_verified'],
      fragments: const ['email not confirmed'],
    )) {
      return const AuthFailure(
        type: AuthFailureType.emailNotConfirmed,
        message: 'Please confirm your email address before signing in.',
      );
    }

    if (code == 'weak_password' || exception is AuthWeakPasswordException) {
      return const AuthFailure(
        type: AuthFailureType.weakPassword,
        message: 'Please choose a stronger password.',
      );
    }

    if (_hasCodeOrMessage(
      code: code,
      message: message,
      codes: const ['user_already_exists', 'email_exists'],
      fragments: const ['already registered', 'already exists'],
    )) {
      return const AuthFailure(
        type: AuthFailureType.emailAlreadyInUse,
        message: 'An account already exists for this email address.',
      );
    }

    if (_hasCodeOrMessage(
      code: code,
      message: message,
      codes: const ['over_request_rate_limit', 'too_many_requests'],
      fragments: const ['rate limit', 'too many requests'],
    )) {
      return const AuthFailure(
        type: AuthFailureType.rateLimited,
        message: 'Too many attempts. Please wait a moment and try again.',
      );
    }

    if (_hasCodeOrMessage(
      code: code,
      message: message,
      codes: const ['signup_disabled'],
      fragments: const ['signup disabled', 'signups not allowed'],
    )) {
      return const AuthFailure(
        type: AuthFailureType.signupDisabled,
        message: 'Sign up is not available right now.',
      );
    }

    if (_hasCodeOrMessage(
      code: code,
      message: message,
      codes: const ['otp_expired', 'otp_disabled'],
      fragments: const ['otp expired', 'token has expired'],
    )) {
      return const AuthFailure(
        type: AuthFailureType.otpExpired,
        message: 'This verification code has expired. Please request a new one.',
      );
    }

    if (_hasCodeOrMessage(
      code: code,
      message: message,
      codes: const ['reauthentication_needed'],
      fragments: const ['reauthentication'],
    )) {
      return const AuthFailure(
        type: AuthFailureType.reauthenticationRequired,
        message: 'Please sign in again to continue.',
      );
    }

    if (_hasCodeOrMessage(
      code: code,
      message: message,
      codes: const ['provider_disabled', 'provider_email_needs_verification'],
      fragments: const ['provider is disabled'],
    )) {
      return const AuthFailure(
        type: AuthFailureType.providerDisabled,
        message: 'This sign-in method is not available right now.',
      );
    }

    if (exception.statusCode == '401' || exception.statusCode == '403') {
      return const AuthFailure(
        type: AuthFailureType.sessionExpired,
        message: 'Your session has expired. Please sign in again.',
      );
    }

    return const AuthFailure(
      type: AuthFailureType.unknown,
      message: 'We could not complete authentication. Please try again.',
    );
  }

  bool _hasCodeOrMessage({
    required String? code,
    required String message,
    required List<String> codes,
    required List<String> fragments,
  }) {
    return codes.contains(code) ||
        fragments.any((fragment) => message.contains(fragment));
  }
}
