import 'dart:async';

import 'package:cinmovies_app/core/error/app_error.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:equatable/equatable.dart';

sealed class Result<T> extends Equatable {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;

  @override
  List<Object?> get props => [data];
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);

  final AppError error;

  @override
  List<Object?> get props => [error];
}

extension ResultExtension<T> on Result<T> {
  R when<R>({
    required R Function(T data) onSuccess,
    required R Function(AppError error) onFailure,
  }) {
    return switch (this) {
      Success(:final data) => onSuccess(data),
      Failure(:final error) => onFailure(error),
    };
  }

  T? getOrNull() => switch (this) {
    Success(:final data) => data,
    Failure() => null,
  };

  T getOrElse(T Function() fallback) => switch (this) {
    Success(:final data) => data,
    Failure() => fallback(),
  };

  AppError? get errorOrNull => switch (this) {
    Success() => null,
    Failure(:final error) => error,
  };

  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is Failure<T>;

  Result<R> map<R>(R Function(T data) transform) => switch (this) {
    Success(:final data) => Success(transform(data)),
    Failure(:final error) => Failure(error),
  };

  Result<R> flatMap<R>(Result<R> Function(T data) transform) => switch (this) {
    Success(:final data) => transform(data),
    Failure(:final error) => Failure(error),
  };

  Future<Result<R>> flatMapAsync<R>(
    Future<Result<R>> Function(T data) transform,
  ) async => switch (this) {
    Success(:final data) => await transform(data),
    Failure(:final error) => Failure(error),
  };
}

extension ErrorMapperResultExtension on ErrorMapper {
  Future<Result<T>> capture<T>(FutureOr<T> Function() operation) async {
    try {
      return Success(await operation());
    } catch (exception) {
      return toFailure<T>(exception);
    }
  }

  Failure<T> toFailure<T>(Object exception) {
    return Failure(map(exception));
  }
}
