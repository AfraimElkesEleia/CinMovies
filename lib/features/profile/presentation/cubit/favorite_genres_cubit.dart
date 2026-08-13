import 'package:cinmovies_app/core/error/app_error.dart';
import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/features/preferences/data/genre_preferences_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum FavoriteGenresStatus { initial, loading, loaded, saving, saved, failure }

class FavoriteGenresState extends Equatable {
  const FavoriteGenresState({
    this.status = FavoriteGenresStatus.initial,
    this.selectedGenres = const {},
    this.failure,
  });

  final FavoriteGenresStatus status;
  final Set<String> selectedGenres;
  final AppError? failure;

  bool get canSave => selectedGenres.length >= 3;
  bool get isBusy =>
      status == FavoriteGenresStatus.loading ||
      status == FavoriteGenresStatus.saving;

  FavoriteGenresState copyWith({
    FavoriteGenresStatus? status,
    Set<String>? selectedGenres,
    AppError? failure,
    bool clearFailure = false,
  }) {
    return FavoriteGenresState(
      status: status ?? this.status,
      selectedGenres: selectedGenres ?? this.selectedGenres,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [status, selectedGenres, failure];
}

class FavoriteGenresCubit extends Cubit<FavoriteGenresState> {
  FavoriteGenresCubit(this._repository) : super(const FavoriteGenresState());

  final GenrePreferencesRepository _repository;

  Future<void> load() async {
    emit(
      state.copyWith(status: FavoriteGenresStatus.loading, clearFailure: true),
    );
    final result = await _repository.loadFavoriteGenres();
    result.when(
      onSuccess: (genres) => emit(
        state.copyWith(
          status: FavoriteGenresStatus.loaded,
          selectedGenres: genres,
        ),
      ),
      onFailure: (error) => emit(
        state.copyWith(status: FavoriteGenresStatus.failure, failure: error),
      ),
    );
  }

  void toggleGenre(String genre) {
    if (state.isBusy) return;
    final nextGenres = {...state.selectedGenres};
    nextGenres.contains(genre)
        ? nextGenres.remove(genre)
        : nextGenres.add(genre);
    emit(state.copyWith(selectedGenres: nextGenres, clearFailure: true));
  }

  Future<void> save() async {
    if (!state.canSave || state.isBusy) return;

    emit(
      state.copyWith(status: FavoriteGenresStatus.saving, clearFailure: true),
    );
    final result = await _repository.saveFavoriteGenres(state.selectedGenres);
    result.when(
      onSuccess: (_) =>
          emit(state.copyWith(status: FavoriteGenresStatus.saved)),
      onFailure: (error) => emit(
        state.copyWith(status: FavoriteGenresStatus.failure, failure: error),
      ),
    );
  }
}
