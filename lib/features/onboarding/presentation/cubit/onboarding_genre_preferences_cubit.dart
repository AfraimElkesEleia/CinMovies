import 'package:cinmovies_app/features/preferences/data/genre_preferences_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum OnboardingGenrePreferencesStatus { initial, saving, saved, failure }

class OnboardingGenrePreferencesState extends Equatable {
  const OnboardingGenrePreferencesState({
    this.selectedGenres = const {},
    this.status = OnboardingGenrePreferencesStatus.initial,
  });

  final Set<String> selectedGenres;
  final OnboardingGenrePreferencesStatus status;

  bool get canContinue => selectedGenres.length >= 3;
  bool get isSaving => status == OnboardingGenrePreferencesStatus.saving;

  OnboardingGenrePreferencesState copyWith({
    Set<String>? selectedGenres,
    OnboardingGenrePreferencesStatus? status,
  }) {
    return OnboardingGenrePreferencesState(
      selectedGenres: selectedGenres ?? this.selectedGenres,
      status: status ?? this.status,
    );
  }

  @override
  List<Object> get props => [selectedGenres, status];
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
    nextGenres.contains(genre) ? nextGenres.remove(genre) : nextGenres.add(genre);
    emit(state.copyWith(selectedGenres: nextGenres));
  }

  Future<void> save() async {
    if (!state.canContinue || state.isSaving) return;

    emit(state.copyWith(status: OnboardingGenrePreferencesStatus.saving));
    try {
      await _repository.saveFavoriteGenres(state.selectedGenres);
      emit(state.copyWith(status: OnboardingGenrePreferencesStatus.saved));
    } catch (_) {
      emit(state.copyWith(status: OnboardingGenrePreferencesStatus.failure));
    }
  }
}
