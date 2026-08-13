import 'dart:typed_data';

import 'package:cinmovies_app/core/error/app_error.dart';
import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:cinmovies_app/features/preferences/data/genre_preferences_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AuthSubmissionStatus { initial, loading, success, failure }

enum AuthSubmissionOperation { login, signup, guest }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthSubmissionStatus.initial,
    this.operation,
    this.failure,
    this.termsAccepted = false,
  });

  final AuthSubmissionStatus status;
  final AuthSubmissionOperation? operation;
  final AppError? failure;
  final bool termsAccepted;

  bool get isLoading => status == AuthSubmissionStatus.loading;

  bool isLoadingOperation(AuthSubmissionOperation value) {
    return isLoading && operation == value;
  }

  AuthState copyWith({
    AuthSubmissionStatus? status,
    AuthSubmissionOperation? operation,
    AppError? failure,
    bool clearFailure = false,
    bool? termsAccepted,
  }) {
    return AuthState(
      status: status ?? this.status,
      operation: operation ?? this.operation,
      failure: clearFailure ? null : failure ?? this.failure,
      termsAccepted: termsAccepted ?? this.termsAccepted,
    );
  }

  @override
  List<Object?> get props => [status, operation, failure, termsAccepted];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._authRepository, this._preferenceRepository)
    : super(const AuthState());

  final AuthRepository _authRepository;
  final GenrePreferencesRepository _preferenceRepository;

  void setTermsAccepted(bool value) {
    emit(state.copyWith(termsAccepted: value));
  }

  Future<void> login({required String email, required String password}) async {
    emit(
      state.copyWith(
        status: AuthSubmissionStatus.loading,
        operation: AuthSubmissionOperation.login,
        clearFailure: true,
      ),
    );
    final result = await _authRepository.signIn(
      email: email,
      password: password,
    );

    await result.when(
      onSuccess: (_) async {
        await _syncCachedGenres();
        emit(state.copyWith(status: AuthSubmissionStatus.success));
      },
      onFailure: (error) async {
        emit(
          state.copyWith(status: AuthSubmissionStatus.failure, failure: error),
        );
      },
    );
  }

  Future<void> continueAsGuest() async {
    emit(
      state.copyWith(
        status: AuthSubmissionStatus.loading,
        operation: AuthSubmissionOperation.guest,
        clearFailure: true,
      ),
    );
    final result = await _authRepository.continueAsGuest();
    result.when(
      onSuccess: (_) =>
          emit(state.copyWith(status: AuthSubmissionStatus.success)),
      onFailure: (error) => emit(
        state.copyWith(status: AuthSubmissionStatus.failure, failure: error),
      ),
    );
  }

  Future<void> signup({
    required String fullName,
    required String email,
    required String password,
    Uint8List? avatarBytes,
    String? avatarFileName,
    String? avatarContentType,
  }) async {
    if (!state.termsAccepted) {
      emit(
        state.copyWith(
          status: AuthSubmissionStatus.failure,
          failure: const ValidationAppError(
            message: 'Please agree to the terms first.',
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: AuthSubmissionStatus.loading,
        operation: AuthSubmissionOperation.signup,
        clearFailure: true,
      ),
    );
    final result = await _authRepository.signUp(
      fullName: fullName,
      email: email,
      password: password,
      avatarBytes: avatarBytes,
      avatarFileName: avatarFileName,
      avatarContentType: avatarContentType,
    );

    await result.when(
      onSuccess: (_) async {
        await _syncCachedGenres();
        emit(state.copyWith(status: AuthSubmissionStatus.success));
      },
      onFailure: (error) async {
        emit(
          state.copyWith(status: AuthSubmissionStatus.failure, failure: error),
        );
      },
    );
  }

  Future<bool> logout() async {
    final result = await _authRepository.signOut();
    return result.when(
      onSuccess: (_) => true,
      onFailure: (error) {
        emit(
          state.copyWith(status: AuthSubmissionStatus.failure, failure: error),
        );
        return false;
      },
    );
  }

  Future<void> _syncCachedGenres() async {
    // syncCachedFavoriteGenres now returns Result<void>.
    // Keep the Hive cache. The next login/startup can retry the sync.
    await _preferenceRepository.syncCachedFavoriteGenres();
  }
}
