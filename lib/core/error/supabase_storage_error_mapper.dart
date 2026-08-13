import 'package:cinmovies_app/core/error/app_error.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabaseStorageErrorMapper implements ErrorMappingRule {
  const SupabaseStorageErrorMapper();

  @override
  AppError? tryMap(Object exception) {
    if (exception is! StorageException) return null;

    final status = exception.statusCode;
    final message = '${exception.error ?? ''} ${exception.message}'
        .toLowerCase();
    if (status == '401' || status == '403') {
      return const StorageAppError(
        message: 'You do not have permission to access this file.',
      );
    }
    if (status == '404' || message.contains('not found')) {
      return const StorageAppError(
        message: 'We could not find the requested file.',
      );
    }
    if (status == '409' || message.contains('already exists')) {
      return const StorageAppError(
        message: 'A file with this name already exists.',
      );
    }
    if (status == '413' ||
        message.contains('too large') ||
        message.contains('exceeded')) {
      return const StorageAppError(
        message: 'This file is too large to upload.',
      );
    }
    if (status == '400' ||
        status == '415' ||
        message.contains('mime type') ||
        message.contains('file type')) {
      return const StorageAppError(
        message:
            'This image could not be uploaded. Please choose a JPG or PNG file.',
      );
    }
    if (status == '507' || message.contains('quota')) {
      return const StorageAppError(
        message: 'Storage is full. Please free up space and try again.',
      );
    }
    if (status == '500' || status == '503') {
      return const StorageAppError(
        message: 'File storage is temporarily unavailable. Please try again.',
      );
    }
    return const StorageAppError(
      message: 'We could not process this file. Please try again.',
    );
  }
}
