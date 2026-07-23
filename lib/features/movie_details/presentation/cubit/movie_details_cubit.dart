import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';
import 'package:cinmovies_app/features/movie_details/presentation/model/movie_details_tab.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MovieDetailsState extends Equatable {
  const MovieDetailsState({
    this.activeTab = MovieDetailsTab.overview,
    this.isFavorite = false,
    this.inWatchlist = false,
    this.showTrailer = false,
    this.isSaving = false,
  });

  final MovieDetailsTab activeTab;
  final bool isFavorite;
  final bool inWatchlist;
  final bool showTrailer;
  final bool isSaving;

  MovieDetailsState copyWith({
    MovieDetailsTab? activeTab,
    bool? isFavorite,
    bool? inWatchlist,
    bool? showTrailer,
    bool? isSaving,
  }) {
    return MovieDetailsState(
      activeTab: activeTab ?? this.activeTab,
      isFavorite: isFavorite ?? this.isFavorite,
      inWatchlist: inWatchlist ?? this.inWatchlist,
      showTrailer: showTrailer ?? this.showTrailer,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object> get props => [
        activeTab,
        isFavorite,
        inWatchlist,
        showTrailer,
        isSaving,
      ];
}

class MovieDetailsCubit extends Cubit<MovieDetailsState> {
  MovieDetailsCubit(this._repository, this._movie)
      : super(const MovieDetailsState());

  final LibraryRepository _repository;
  final HomeMovieModel _movie;

  Future<void> loadSavedState() async {
    try {
      final results = await Future.wait([
        _repository.contains(_movie, UserMovieListType.favorite),
        _repository.contains(_movie, UserMovieListType.watchlist),
      ]);
      // Silently ignore failures — we'll just leave isFavorite/inWatchlist at false.
      emit(state.copyWith(
        isFavorite: results[0].getOrElse(() => false),
        inWatchlist: results[1].getOrElse(() => false),
      ));
    } catch (_) {}
  }

  void selectTab(MovieDetailsTab tab) {
    emit(state.copyWith(activeTab: tab));
  }

  void showTrailer() => emit(state.copyWith(showTrailer: true));

  void hideTrailer() => emit(state.copyWith(showTrailer: false));

  Future<bool> toggleFavorite() {
    return _toggle(
      type: UserMovieListType.favorite,
      current: state.isFavorite,
      emitOptimistic: (value) => emit(state.copyWith(isFavorite: value)),
    );
  }

  Future<bool> toggleWatchlist() {
    return _toggle(
      type: UserMovieListType.watchlist,
      current: state.inWatchlist,
      emitOptimistic: (value) => emit(state.copyWith(inWatchlist: value)),
    );
  }

  Future<bool> _toggle({
    required UserMovieListType type,
    required bool current,
    required void Function(bool value) emitOptimistic,
  }) async {
    if (state.isSaving) return false;

    final nextValue = !current;
    emit(state.copyWith(isSaving: true));
    emitOptimistic(nextValue);
    try {
      final result = await _repository.setListed(
        _movie,
        type,
        listed: nextValue,
      );
      emit(state.copyWith(isSaving: false));
      return result.fold((_) {
        // Revert optimistic update on failure.
        emitOptimistic(current);
        return false;
      }, (_) => true);
    } catch (_) {
      emitOptimistic(current);
      emit(state.copyWith(isSaving: false));
      return false;
    }
  }
}

