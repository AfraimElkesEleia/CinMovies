import 'package:cinmovies_app/features/onboarding_screen/data/preference_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum PreferenceStatus { initial, saving, saved, failure }

class PreferenceState extends Equatable {
  const PreferenceState({
    this.selectedGenres = const {},
    this.status = PreferenceStatus.initial,
  });

  final Set<String> selectedGenres;
  final PreferenceStatus status;

  bool get canContinue => selectedGenres.length >= 3;
  bool get isSaving => status == PreferenceStatus.saving;

  PreferenceState copyWith({
    Set<String>? selectedGenres,
    PreferenceStatus? status,
  }) {
    return PreferenceState(
      selectedGenres: selectedGenres ?? this.selectedGenres,
      status: status ?? this.status,
    );
  }

  @override
  List<Object> get props => [selectedGenres, status];
}

class PreferenceCubit extends Cubit<PreferenceState> {
  PreferenceCubit(this._repository)
      : super(
          PreferenceState(selectedGenres: _repository.cachedFavoriteGenres()),
        );

  final PreferenceRepository _repository;

  void toggleGenre(String genre) {
    final nextGenres = {...state.selectedGenres};
    nextGenres.contains(genre) ? nextGenres.remove(genre) : nextGenres.add(genre);
    emit(state.copyWith(selectedGenres: nextGenres));
  }

  Future<void> save() async {
    if (!state.canContinue || state.isSaving) return;

    emit(state.copyWith(status: PreferenceStatus.saving));
    try {
      await _repository.saveSelectedGenres(state.selectedGenres);
      emit(state.copyWith(status: PreferenceStatus.saved));
    } catch (_) {
      emit(state.copyWith(status: PreferenceStatus.failure));
    }
  }
}
