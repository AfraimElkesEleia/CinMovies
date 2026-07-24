import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/features/browse/data/browse_genre.dart';
import 'package:cinmovies_app/features/browse/data/browse_repository.dart';
import 'package:cinmovies_app/features/home/presentation/data/home_mock_data.dart';
import 'package:cinmovies_app/features/home/data/model/home_movie_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BrowseState extends Equatable {
  const BrowseState({
    required this.status,
    required this.genres,
    required this.activeGenre,
    required this.movies,
    required this.currentPage,
    required this.totalPages,
    this.isLoadingMore = false,
    this.failure,
  });

  const BrowseState.initial()
    : status = BrowseStatus.initial,
      genres = fallbackGenres,
      activeGenre = BrowseGenre.all,
      movies = const [],
      currentPage = 0,
      totalPages = 1,
      isLoadingMore = false,
      failure = null;

  static const fallbackGenres = [
    BrowseGenre.all,
    BrowseGenre(id: 28, name: 'Action'),
    BrowseGenre(id: 12, name: 'Adventure'),
    BrowseGenre(name: 'Hero'),
    BrowseGenre(id: 878, name: 'Sci-Fi'),
    BrowseGenre(id: 18, name: 'Drama'),
  ];

  final BrowseStatus status;
  final List<BrowseGenre> genres;
  final BrowseGenre activeGenre;
  final List<HomeMovieModel> movies;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final Failure? failure;

  bool get canLoadMore => currentPage < totalPages;

  BrowseState copyWith({
    BrowseStatus? status,
    List<BrowseGenre>? genres,
    BrowseGenre? activeGenre,
    List<HomeMovieModel>? movies,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
    Failure? failure,
  }) {
    return BrowseState(
      status: status ?? this.status,
      genres: genres ?? this.genres,
      activeGenre: activeGenre ?? this.activeGenre,
      movies: movies ?? this.movies,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    genres,
    activeGenre,
    movies,
    currentPage,
    totalPages,
    isLoadingMore,
    failure,
  ];
}

enum BrowseStatus { initial, loading, loaded, failure }

class BrowseCubit extends Cubit<BrowseState> {
  BrowseCubit(this._repository) : super(const BrowseState.initial());

  final BrowseRepository _repository;

  Future<void> loadInitial() async {
    emit(state.copyWith(status: BrowseStatus.loading, failure: null));

    final genresResult = await _repository.fetchGenres();
    final genres = genresResult.getOrElse(() => BrowseState.fallbackGenres);

    final moviesResult = await _repository.fetchMovies(
      page: 1,
      genre: BrowseGenre.all,
    );

    moviesResult.fold(
      (failure) => emit(
        BrowseState(
          status: BrowseStatus.failure,
          genres: genres,
          activeGenre: BrowseGenre.all,
          movies: kHomeMovies,
          currentPage: 1,
          totalPages: 1,
          failure: failure,
        ),
      ),
      (page) => emit(
        BrowseState(
          status: BrowseStatus.loaded,
          genres: genres,
          activeGenre: BrowseGenre.all,
          movies: page.movies.isEmpty ? kHomeMovies : page.movies,
          currentPage: page.page,
          totalPages: page.totalPages,
        ),
      ),
    );
  }

  Future<void> setGenre(BrowseGenre genre) async {
    if (genre == state.activeGenre && state.status == BrowseStatus.loaded) {
      return;
    }

    emit(
      state.copyWith(
        status: BrowseStatus.loading,
        activeGenre: genre,
        movies: const [],
        currentPage: 0,
        totalPages: 1,
        isLoadingMore: false,
        failure: null,
      ),
    );

    final result = await _repository.fetchMovies(page: 1, genre: genre);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: BrowseStatus.failure,
          movies: _fallbackMoviesForGenre(genre),
          currentPage: 1,
          totalPages: 1,
          failure: failure,
        ),
      ),
      (page) => emit(
        state.copyWith(
          status: BrowseStatus.loaded,
          movies: page.movies,
          currentPage: page.page,
          totalPages: page.totalPages,
          failure: null,
        ),
      ),
    );
  }

  Future<void> loadNextPage() async {
    if (state.status != BrowseStatus.loaded ||
        state.isLoadingMore ||
        !state.canLoadMore) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true, failure: null));

    final result = await _repository.fetchMovies(
      page: state.currentPage + 1,
      genre: state.activeGenre,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(isLoadingMore: false, failure: failure),
      ),
      (page) => emit(
        state.copyWith(
          movies: [...state.movies, ...page.movies],
          currentPage: page.page,
          totalPages: page.totalPages,
          isLoadingMore: false,
          failure: null,
        ),
      ),
    );
  }

  List<HomeMovieModel> _fallbackMoviesForGenre(BrowseGenre genre) {
    if (genre.isAll) return kHomeMovies;
    return kHomeMovies
        .where((movie) => movie.genres.contains(genre.name))
        .toList();
  }
}
