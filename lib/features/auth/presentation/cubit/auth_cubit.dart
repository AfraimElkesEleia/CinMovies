import 'dart:typed_data';

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
    this.errorMessage,
    this.termsAccepted = false,
  });

  final AuthSubmissionStatus status;
  final AuthSubmissionOperation? operation;
  final String? errorMessage;
  final bool termsAccepted;

  bool get isLoading => status == AuthSubmissionStatus.loading;

  bool isLoadingOperation(AuthSubmissionOperation value) {
    return isLoading && operation == value;
  }

  AuthState copyWith({
    AuthSubmissionStatus? status,
    AuthSubmissionOperation? operation,
    String? errorMessage,
    bool clearError = false,
    bool? termsAccepted,
  }) {
    return AuthState(
      status: status ?? this.status,
      operation: operation ?? this.operation,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      termsAccepted: termsAccepted ?? this.termsAccepted,
    );
  }

  @override
  List<Object?> get props => [
    status,
    operation,
    errorMessage,
    termsAccepted,
  ];
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
        clearError: true,
      ),
    );
    final result = await _authRepository.signIn(
      email: email,
      password: password,
    );

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: AuthSubmissionStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
      (_) async {
        await _syncCachedGenres();
        emit(state.copyWith(status: AuthSubmissionStatus.success));
      },
    );
  }

  Future<void> continueAsGuest() async {
    emit(
      state.copyWith(
        status: AuthSubmissionStatus.loading,
        operation: AuthSubmissionOperation.guest,
        clearError: true,
      ),
    );
    final result = await _authRepository.continueAsGuest();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthSubmissionStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(state.copyWith(status: AuthSubmissionStatus.success)),
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
          errorMessage: 'Please agree to the terms first.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: AuthSubmissionStatus.loading,
        operation: AuthSubmissionOperation.signup,
        clearError: true,
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

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: AuthSubmissionStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
      (_) async {
        await _syncCachedGenres();
        emit(state.copyWith(status: AuthSubmissionStatus.success));
      },
    );
  }

  Future<void> logout() => _authRepository.signOut();

  Future<void> _syncCachedGenres() async {
    try {
      await _preferenceRepository.syncCachedFavoriteGenres();
    } catch (_) {
      // Keep the Hive cache. The next login/startup can retry the sync.
    }
  }
}
