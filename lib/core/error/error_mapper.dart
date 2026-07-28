import 'package:cinmovies_app/core/error/exceptions.dart';
import 'package:cinmovies_app/core/error/failures.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Failure mapError(Object error) {
  return Failure(message: _messageFor(error));
}

String _messageFor(Object error) {
  if (error is ServerException) return error.message;
  if (error is DioException) return _dioMessage(error);
  if (error is AuthException) return _authMessage(error);
  if (error is PostgrestException) return _databaseMessage(error);
  if (error is StorageException) return _storageMessage(error);
  return 'Something went wrong. Please try again.';
}

String _dioMessage(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return 'Please check your internet connection and try again.';
    default:
      break;
  }

  return switch (error.response?.statusCode) {
    400 => 'Please check the information and try again.',
    401 || 403 => 'You do not have permission to do that.',
    404 => 'We could not find the requested data.',
    408 => 'The request timed out. Please try again.',
    409 => 'This action conflicts with existing data.',
    429 => 'Too many attempts. Please wait a moment and try again.',
    500 || 502 || 503 || 504 =>
      'The service is temporarily unavailable. Please try again.',
    _ => 'Something went wrong. Please try again.',
  };
}

String _authMessage(AuthException error) {
  final code = error.code;
  final message = error.message.toLowerCase();

  if (code == 'invalid_credentials' ||
      code == 'bad_jwt' ||
      message.contains('invalid login credentials')) {
    return 'The email or password is incorrect.';
  }
  if (code == 'email_not_confirmed' ||
      code == 'email_not_verified' ||
      message.contains('email not confirmed')) {
    return 'Please confirm your email address before signing in.';
  }
  if (code == 'weak_password' || error is AuthWeakPasswordException) {
    return 'Please choose a stronger password.';
  }
  if (code == 'user_already_exists' ||
      code == 'email_exists' ||
      message.contains('already registered')) {
    return 'An account already exists for this email address.';
  }
  if (code == 'over_request_rate_limit' ||
      code == 'too_many_requests' ||
      message.contains('rate limit')) {
    return 'Too many attempts. Please wait a moment and try again.';
  }
  if (code == 'signup_disabled') {
    return 'Sign up is not available right now.';
  }
  if (code == 'otp_expired' || message.contains('token has expired')) {
    return 'This verification code has expired. Please request a new one.';
  }
  if (code == 'reauthentication_needed') {
    return 'Please sign in again to continue.';
  }
  if (code == 'provider_disabled') {
    return 'This sign-in method is not available right now.';
  }
  if (error.statusCode == '401' || error.statusCode == '403') {
    return 'Your session has expired. Please sign in again.';
  }
  return 'We could not complete authentication. Please try again.';
}

String _databaseMessage(PostgrestException error) {
  return switch (error.code) {
    '23505' => 'This item already exists.',
    '23503' => 'This action references data that no longer exists.',
    '42501' => 'You do not have permission to do that.',
    'PGRST116' => 'We could not find the requested data.',
    '22P02' || '23502' || '23514' =>
      'Please check the information and try again.',
    'PGRST000' || 'PGRST001' || 'PGRST002' || 'PGRST003' =>
      'The service is temporarily unavailable. Please try again.',
    _ when error.message.toLowerCase().contains('permission denied') ||
        error.message.toLowerCase().contains('row-level security') =>
      'You do not have permission to do that.',
    _ => 'We could not save your changes. Please try again.',
  };
}

String _storageMessage(StorageException error) {
  final status = error.statusCode;
  final message =
      '${error.error ?? ''} ${error.message}'.toLowerCase();

  if (status == '401' || status == '403') {
    return 'You do not have permission to access this file.';
  }
  if (status == '404' || message.contains('not found')) {
    return 'We could not find the requested file.';
  }
  if (status == '409' || message.contains('already exists')) {
    return 'A file with this name already exists.';
  }
  if (status == '413' ||
      message.contains('too large') ||
      message.contains('exceeded')) {
    return 'This file is too large to upload.';
  }
  if (status == '400' ||
      status == '415' ||
      message.contains('mime type') ||
      message.contains('file type')) {
    return 'This image could not be uploaded. Please choose a JPG or PNG file.';
  }
  if (status == '507' || message.contains('quota')) {
    return 'Storage is full. Please free up space and try again.';
  }
  if (status == '500' || status == '503') {
    return 'File storage is temporarily unavailable. Please try again.';
  }
  return 'We could not process this file. Please try again.';
}
