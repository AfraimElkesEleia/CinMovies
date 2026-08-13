import 'package:cinmovies_app/core/error/app_error.dart';
import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/features/preferences/data/genre_preferences_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum OnboardingGenrePreferencesStatus { initial, saving, saved, failure }

class OnboardingGenrePreferencesState extends Equatable {
  const OnboardingGenrePreferencesState({
    this.selectedGenres = const {},
    this.status = OnboardingGenrePreferencesStatus.initial,
    this.failure,
  });

  final Set<String> selectedGenres;
  final OnboardingGenrePreferencesStatus status;
  final AppError? failure;

  bool get canContinue => selectedGenres.length >= 3;
  bool get isSaving => status == OnboardingGenrePreferencesStatus.saving;

  OnboardingGenrePreferencesState copyWith({
    Set<String>? selectedGenres,
    OnboardingGenrePreferencesStatus? status,
    AppError? failure,
    bool clearFailure = false,
  }) {
    return OnboardingGenrePreferencesState(
      selectedGenres: selectedGenres ?? this.selectedGenres,
      status: status ?? this.status,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [selectedGenres, status, failure];
}

class OnboardingGenrePreferencesCubit
    extends Cubit<OnboardingGenrePreferencesState> {
  OnboardingGenrePreferencesCubit(this._repository)
    : super(
        OnboardingGenrePreferencesState(
          selectedGenres: _repository.cachedFavoriteGenres(),
        ),
      );

  final GenrePreferencesRepository _repository;

  void toggleGenre(String genre) {
    final nextGenres = {...state.selectedGenres};
    nextGenres.contains(genre)
        ? nextGenres.remove(genre)
        : nextGenres.add(genre);
    emit(state.copyWith(selectedGenres: nextGenres));
  }

  Future<void> save() async {
    if (!state.canContinue || state.isSaving) return;

    emit(
      state.copyWith(
        status: OnboardingGenrePreferencesStatus.saving,
        clearFailure: true,
      ),
    );
    final result = await _repository.saveFavoriteGenres(state.selectedGenres);
    result.when(
      onSuccess: (_) =>
          emit(state.copyWith(status: OnboardingGenrePreferencesStatus.saved)),
      onFailure: (error) => emit(
        state.copyWith(
          status: OnboardingGenrePreferencesStatus.failure,
          failure: error,
        ),
      ),
    );
  }
}
