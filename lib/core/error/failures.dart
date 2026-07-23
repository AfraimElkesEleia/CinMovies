import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({required String message, this.statusCode})
    : super(message);

  @override
  List<Object?> get props => [message, statusCode];
}

class CacheFailure extends Failure {
  const CacheFailure({required String message}) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure({required String message}) : super(message);
}

class UnknownFailure extends Failure {
  const UnknownFailure({required String message}) : super(message);
}

enum AuthFailureType {
  invalidCredentials,
  emailNotConfirmed,
  weakPassword,
  emailAlreadyInUse,
  sessionExpired,
  rateLimited,
  signupDisabled,
  otpExpired,
  reauthenticationRequired,
  providerDisabled,
  unknown,
}

class AuthFailure extends Failure {
  final AuthFailureType type;

  const AuthFailure({
    required this.type,
    required String message,
  }) : super(message);

  @override
  List<Object?> get props => [type, message];
}

enum DatabaseFailureType {
  uniqueViolation,
  foreignKeyViolation,
  permissionDenied,
  notFound,
  invalidInput,
  unavailable,
  unknown,
}

class DatabaseFailure extends Failure {
  final DatabaseFailureType type;

  const DatabaseFailure({
    required this.type,
    required String message,
  }) : super(message);

  @override
  List<Object?> get props => [type, message];
}

enum StorageFailureType {
  notFound,
  alreadyExists,
  permissionDenied,
  payloadTooLarge,
  invalidFile,
  quotaExceeded,
  unavailable,
  unknown,
}

class StorageFailure extends Failure {
  final StorageFailureType type;

  const StorageFailure({
    required this.type,
    required String message,
  }) : super(message);

  @override
  List<Object?> get props => [type, message];
}
