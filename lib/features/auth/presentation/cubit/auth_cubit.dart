import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:cinmovies_app/features/onboarding_screen/data/preference_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AuthSubmissionStatus { initial, loading, success, failure }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthSubmissionStatus.initial,
    this.errorMessage,
    this.rememberMe = false,
    this.termsAccepted = false,
  });

  final AuthSubmissionStatus status;
  final String? errorMessage;
  final bool rememberMe;
  final bool termsAccepted;

  bool get isLoading => status == AuthSubmissionStatus.loading;

  AuthState copyWith({
    AuthSubmissionStatus? status,
    String? errorMessage,
    bool clearError = false,
    bool? rememberMe,
    bool? termsAccepted,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      rememberMe: rememberMe ?? this.rememberMe,
      termsAccepted: termsAccepted ?? this.termsAccepted,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        rememberMe,
        termsAccepted,
      ];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._authRepository, this._preferenceRepository)
      : super(const AuthState());

  final AuthRepository _authRepository;
  final PreferenceRepository _preferenceRepository;

  void setRememberMe(bool value) {
    emit(state.copyWith(rememberMe: value));
  }

  void setTermsAccepted(bool value) {
    emit(state.copyWith(termsAccepted: value));
  }

  Future<void> login({required String email, required String password}) async {
    emit(state.copyWith(status: AuthSubmissionStatus.loading, clearError: true));
    try {
      await _authRepository.signIn(email: email, password: password);
      await _syncCachedGenres();
      emit(state.copyWith(status: AuthSubmissionStatus.success));
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthSubmissionStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> signup({
    required String fullName,
    required String email,
    required String password,
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

    emit(state.copyWith(status: AuthSubmissionStatus.loading, clearError: true));
    try {
      await _authRepository.signUp(
        fullName: fullName,
        email: email,
        password: password,
      );
      await _syncCachedGenres();
      emit(state.copyWith(status: AuthSubmissionStatus.success));
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthSubmissionStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
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
