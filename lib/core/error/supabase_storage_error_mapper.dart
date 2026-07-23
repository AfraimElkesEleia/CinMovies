import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageErrorMapper implements ErrorMapper {
  const SupabaseStorageErrorMapper();

  @override
  Failure? tryMap(Object exception) {
    if (exception is! StorageException) return null;
    return _mapStorage(exception);
  }

  StorageFailure _mapStorage(StorageException exception) {
    final statusCode = exception.statusCode;
    final error = exception.error?.toLowerCase() ?? '';
    final message = exception.message.toLowerCase();

    if (statusCode == '401' || statusCode == '403') {
      return const StorageFailure(
        type: StorageFailureType.permissionDenied,
        message: 'You do not have permission to access this file.',
      );
    }

    if (statusCode == '404' ||
        error.contains('not found') ||
        message.contains('not found')) {
      return const StorageFailure(
        type: StorageFailureType.notFound,
        message: 'We could not find the requested file.',
      );
    }

    if (statusCode == '409' ||
        error.contains('already exists') ||
        message.contains('already exists')) {
      return const StorageFailure(
        type: StorageFailureType.alreadyExists,
        message: 'A file with this name already exists.',
      );
    }

    if (statusCode == '413' ||
        message.contains('too large') ||
        message.contains('exceeded')) {
      return const StorageFailure(
        type: StorageFailureType.payloadTooLarge,
        message: 'This file is too large to upload.',
      );
    }

    if (statusCode == '400' ||
        statusCode == '415' ||
        message.contains('mime type') ||
        message.contains('file type')) {
      return const StorageFailure(
        type: StorageFailureType.invalidFile,
        message: 'This image could not be uploaded. Please choose a JPG or PNG file.',
      );
    }

    if (statusCode == '507' || message.contains('quota')) {
      return const StorageFailure(
        type: StorageFailureType.quotaExceeded,
        message: 'Storage is full. Please free up space and try again.',
      );
    }

    if (statusCode == '500' || statusCode == '503') {
      return const StorageFailure(
        type: StorageFailureType.unavailable,
        message: 'File storage is temporarily unavailable. Please try again.',
      );
    }

    return const StorageFailure(
      type: StorageFailureType.unknown,
      message: 'We could not process this file. Please try again.',
    );
  }
}
