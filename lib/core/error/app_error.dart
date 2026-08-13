import 'package:equatable/equatable.dart';

sealed class AppError extends Equatable {
  const AppError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

final class NetworkAppError extends AppError {
  const NetworkAppError({required super.message});
}

final class AuthenticationAppError extends AppError {
  const AuthenticationAppError({required super.message});
}

final class ValidationAppError extends AppError {
  const ValidationAppError({required super.message});
}

final class ServerAppError extends AppError {
  const ServerAppError({required super.message});
}

final class DatabaseAppError extends AppError {
  const DatabaseAppError({required super.message});
}

final class StorageAppError extends AppError {
  const StorageAppError({required super.message});
}

final class UnknownAppError extends AppError {
  const UnknownAppError({required super.message});
}
