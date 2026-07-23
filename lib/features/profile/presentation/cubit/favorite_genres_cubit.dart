import 'package:cinmovies_app/features/onboarding_screen/data/preference_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum FavoriteGenresStatus { initial, loading, loaded, saving, saved, failure }

class FavoriteGenresState extends Equatable {
  const FavoriteGenresState({
    this.status = FavoriteGenresStatus.initial,
    this.selectedGenres = const {},
    this.errorMessage,
  });

  final FavoriteGenresStatus status;
  final Set<String> selectedGenres;
  final String? errorMessage;

  bool get canSave => selectedGenres.length >= 3;
  bool get isBusy =>
      status == FavoriteGenresStatus.loading ||
      status == FavoriteGenresStatus.saving;

  FavoriteGenresState copyWith({
    FavoriteGenresStatus? status,
    Set<String>? selectedGenres,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FavoriteGenresState(
      status: status ?? this.status,
      selectedGenres: selectedGenres ?? this.selectedGenres,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, selectedGenres, errorMessage];
}

class FavoriteGenresCubit extends Cubit<FavoriteGenresState> {
  FavoriteGenresCubit(this._repository) : super(const FavoriteGenresState());

  final PreferenceRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: FavoriteGenresStatus.loading, clearError: true));
    try {
      final genres = await _repository.favoriteGenres();
      emit(
        state.copyWith(
          status: FavoriteGenresStatus.loaded,
          selectedGenres: genres,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: FavoriteGenresStatus.failure,
          errorMessage: 'Could not load your favorite genres.',
        ),
      );
    }
  }

  void toggleGenre(String genre) {
    if (state.isBusy) return;
    final nextGenres = {...state.selectedGenres};
    nextGenres.contains(genre) ? nextGenres.remove(genre) : nextGenres.add(genre);
    emit(state.copyWith(selectedGenres: nextGenres, clearError: true));
  }

  Future<void> save() async {
    if (!state.canSave || state.isBusy) return;

    emit(state.copyWith(status: FavoriteGenresStatus.saving, clearError: true));
    try {
      await _repository.saveSelectedGenres(state.selectedGenres);
      emit(state.copyWith(status: FavoriteGenresStatus.saved));
    } catch (_) {
      emit(
        state.copyWith(
          status: FavoriteGenresStatus.failure,
          errorMessage: 'Could not update your favorite genres.',
        ),
      );
    }
  }
}
