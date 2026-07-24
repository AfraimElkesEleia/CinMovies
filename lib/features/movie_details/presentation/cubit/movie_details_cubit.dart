import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/features/home/data/model/home_movie_model.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';
import 'package:cinmovies_app/features/movie_details/data/movie_details_repository.dart';
import 'package:cinmovies_app/features/movie_details/data/model/movie_details_tab.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MovieDetailsState extends Equatable {
  const MovieDetailsState({
    required this.status,
    required this.movie,
    this.similarMovies = const [],
    this.activeTab = MovieDetailsTab.overview,
    this.isDetailsLoading = false,
    this.isFavoriteLoading = false,
    this.isWatchlistLoading = false,
    this.isFavorite = false,
    this.inWatchlist = false,
    this.showTrailer = false,
    this.isFavoriteSaving = false,
    this.isWatchlistSaving = false,
    this.failure,
  });

  const MovieDetailsState.initial(HomeMovieModel movie)
    : this(
        status: MovieDetailsStatus.loaded,
        movie: movie,
        isDetailsLoading: true,
        isFavoriteLoading: true,
        isWatchlistLoading: true,
      );

  final MovieDetailsStatus status;
  final HomeMovieModel movie;
  final List<HomeMovieModel> similarMovies;
  final MovieDetailsTab activeTab;
  final bool isDetailsLoading;
  final bool isFavoriteLoading;
  final bool isWatchlistLoading;
  final bool isFavorite;
  final bool inWatchlist;
  final bool showTrailer;
  final bool isFavoriteSaving;
  final bool isWatchlistSaving;
  final Failure? failure;

  MovieDetailsState copyWith({
    MovieDetailsStatus? status,
    HomeMovieModel? movie,
    List<HomeMovieModel>? similarMovies,
    MovieDetailsTab? activeTab,
    bool? isDetailsLoading,
    bool? isFavoriteLoading,
    bool? isWatchlistLoading,
    bool? isFavorite,
    bool? inWatchlist,
    bool? showTrailer,
    bool? isFavoriteSaving,
    bool? isWatchlistSaving,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return MovieDetailsState(
      status: status ?? this.status,
      movie: movie ?? this.movie,
      similarMovies: similarMovies ?? this.similarMovies,
      activeTab: activeTab ?? this.activeTab,
      isDetailsLoading: isDetailsLoading ?? this.isDetailsLoading,
      isFavoriteLoading: isFavoriteLoading ?? this.isFavoriteLoading,
      isWatchlistLoading: isWatchlistLoading ?? this.isWatchlistLoading,
      isFavorite: isFavorite ?? this.isFavorite,
      inWatchlist: inWatchlist ?? this.inWatchlist,
      showTrailer: showTrailer ?? this.showTrailer,
      isFavoriteSaving: isFavoriteSaving ?? this.isFavoriteSaving,
      isWatchlistSaving: isWatchlistSaving ?? this.isWatchlistSaving,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    movie,
    similarMovies,
    activeTab,
    isDetailsLoading,
    isFavoriteLoading,
    isWatchlistLoading,
    isFavorite,
    inWatchlist,
    showTrailer,
    isFavoriteSaving,
    isWatchlistSaving,
    failure,
  ];
}

enum MovieDetailsStatus { loading, loaded, failure }

class MovieDetailsCubit extends Cubit<MovieDetailsState> {
  MovieDetailsCubit(
    this._detailsRepository,
    this._libraryRepository,
    HomeMovieModel movie,
  ) : super(MovieDetailsState.initial(movie));

  final MovieDetailsRepository _detailsRepository;
  final LibraryRepository _libraryRepository;

  Future<void> load() async {
    emit(
      state.copyWith(
        isDetailsLoading: true,
        isFavoriteLoading: true,
        isWatchlistLoading: true,
        clearFailure: true,
      ),
    );

    await Future.wait([
      _loadDetails(),
      _loadSavedState(UserMovieListType.favorite),
      _loadSavedState(UserMovieListType.watchlist),
    ]);
  }

  Future<void> _loadDetails() async {
    final detailResult = await _detailsRepository.fetchMovieDetails(state.movie);
    if (isClosed) return;

    detailResult.fold(
      (failure) => emit(
        state.copyWith(
          status: MovieDetailsStatus.failure,
          isDetailsLoading: false,
          failure: failure,
        ),
      ),
      (detail) => emit(
        state.copyWith(
          status: MovieDetailsStatus.loaded,
          movie: detail.movie,
          similarMovies: detail.similarMovies,
          isDetailsLoading: false,
          clearFailure: true,
        ),
      ),
    );
  }

  Future<void> _loadSavedState(UserMovieListType type) async {
    final result = await _libraryRepository.contains(state.movie, type);
    if (isClosed) return;

    final isListed = result.getOrElse(() => false);
    switch (type) {
      case UserMovieListType.favorite:
        emit(
          state.copyWith(
            isFavorite: isListed,
            isFavoriteLoading: false,
          ),
        );
      case UserMovieListType.watchlist:
        emit(
          state.copyWith(
            inWatchlist: isListed,
            isWatchlistLoading: false,
          ),
        );
      case UserMovieListType.watched:
      case UserMovieListType.downloaded:
        break;
    }
  }

  void selectTab(MovieDetailsTab tab) {
    emit(state.copyWith(activeTab: tab));
  }

  void showTrailer() => emit(state.copyWith(showTrailer: true));

  void hideTrailer() => emit(state.copyWith(showTrailer: false));

  Future<bool> toggleFavorite() {
    if (state.isFavoriteLoading || state.isFavoriteSaving) return Future.value(false);

    final current = state.isFavorite;
    return _toggle(
      type: UserMovieListType.favorite,
      current: current,
      emitBusy: (isSaving, value) => emit(
        state.copyWith(isFavoriteSaving: isSaving, isFavorite: value),
      ),
    );
  }

  Future<bool> toggleWatchlist() {
    if (state.isWatchlistLoading || state.isWatchlistSaving) {
      return Future.value(false);
    }

    final current = state.inWatchlist;
    return _toggle(
      type: UserMovieListType.watchlist,
      current: current,
      emitBusy: (isSaving, value) => emit(
        state.copyWith(isWatchlistSaving: isSaving, inWatchlist: value),
      ),
    );
  }

  Future<bool> _toggle({
    required UserMovieListType type,
    required bool current,
    required void Function(bool isSaving, bool value) emitBusy,
  }) async {
    final nextValue = !current;
    emitBusy(true, nextValue);
    try {
      final result = await _libraryRepository.setListed(
        state.movie,
        type,
        listed: nextValue,
      );
      return result.fold((_) {
        emitBusy(false, current);
        return false;
      }, (_) {
        emitBusy(false, nextValue);
        return true;
      });
    } catch (_) {
      emitBusy(false, current);
      return false;
    }
  }
}
