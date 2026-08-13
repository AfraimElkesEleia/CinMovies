import 'package:cinmovies_app/core/error/app_error.dart';
import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/features/browse/data/browse_genre.dart';
import 'package:cinmovies_app/features/browse/data/browse_repository.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BrowseState extends Equatable {
  const BrowseState({
    required this.status,
    required this.genres,
    required this.selectedGenre,
    required this.movies,
    required this.currentPage,
    required this.totalPages,
    this.isLoadingMore = false,
    this.failure,
  });

  const BrowseState.initial()
    : status = BrowseStatus.initial,
      genres = fallbackGenres,
      selectedGenre = BrowseGenre.all,
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
  final BrowseGenre selectedGenre;
  final List<Movie> movies;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final AppError? failure;

  bool get canLoadMore => currentPage < totalPages;

  BrowseState copyWith({
    BrowseStatus? status,
    List<BrowseGenre>? genres,
    BrowseGenre? selectedGenre,
    List<Movie>? movies,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
    AppError? failure,
  }) {
    return BrowseState(
      status: status ?? this.status,
      genres: genres ?? this.genres,
      selectedGenre: selectedGenre ?? this.selectedGenre,
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
    selectedGenre,
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

    moviesResult.when(
      onSuccess: (page) => emit(
        BrowseState(
          status: BrowseStatus.loaded,
          genres: genres,
          selectedGenre: BrowseGenre.all,
          movies: page.movies,
          currentPage: page.page,
          totalPages: page.totalPages,
        ),
      ),
      onFailure: (error) => emit(
        BrowseState(
          status: BrowseStatus.failure,
          genres: genres,
          selectedGenre: BrowseGenre.all,
          movies: const [],
          currentPage: 1,
          totalPages: 1,
          failure: error,
        ),
      ),
    );
  }

  Future<void> selectGenre(BrowseGenre genre) async {
    if (genre == state.selectedGenre && state.status == BrowseStatus.loaded) {
      return;
    }

    emit(
      state.copyWith(
        status: BrowseStatus.loading,
        selectedGenre: genre,
        movies: const [],
        currentPage: 0,
        totalPages: 1,
        isLoadingMore: false,
        failure: null,
      ),
    );

    final result = await _repository.fetchMovies(page: 1, genre: genre);
    result.when(
      onSuccess: (page) => emit(
        state.copyWith(
          status: BrowseStatus.loaded,
          movies: page.movies,
          currentPage: page.page,
          totalPages: page.totalPages,
          failure: null,
        ),
      ),
      onFailure: (error) => emit(
        state.copyWith(
          status: BrowseStatus.failure,
          movies: const [],
          currentPage: 1,
          totalPages: 1,
          failure: error,
        ),
      ),
    );
  }

  Future<void> refresh() async {
    final selectedGenre = state.selectedGenre;
    final genresResult = await _repository.fetchGenres();
    final genres = genresResult.getOrElse(() => state.genres);
    final moviesResult = await _repository.fetchMovies(
      page: 1,
      genre: selectedGenre,
    );

    moviesResult.when(
      onSuccess: (page) => emit(
        state.copyWith(
          status: BrowseStatus.loaded,
          genres: genres,
          movies: page.movies,
          currentPage: page.page,
          totalPages: page.totalPages,
          isLoadingMore: false,
          failure: null,
        ),
      ),
      onFailure: (error) => emit(
        state.copyWith(
          status: state.movies.isEmpty
              ? BrowseStatus.failure
              : BrowseStatus.loaded,
          genres: genres,
          isLoadingMore: false,
          failure: error,
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
      genre: state.selectedGenre,
    );

    result.when(
      onSuccess: (page) => emit(
        state.copyWith(
          movies: [...state.movies, ...page.movies],
          currentPage: page.page,
          totalPages: page.totalPages,
          isLoadingMore: false,
          failure: null,
        ),
      ),
      onFailure: (error) =>
          emit(state.copyWith(isLoadingMore: false, failure: error)),
    );
  }
}
