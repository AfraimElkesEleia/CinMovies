import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/features/home/data/home_repository.dart';
import 'package:cinmovies_app/features/home/presentation/model/movie_section_args.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/movies/presentation/model/movie_list_options.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MovieSectionState extends Equatable {
  const MovieSectionState({
    required this.args,
    this.status = MovieListStatus.initial,
    this.movies = const [],
    this.query = '',
    this.sortOption = MovieSortOption.rating,
    this.currentPage = 0,
    this.totalPages = 1,
    this.isLoadingMore = false,
    this.failure,
  });

  final MovieSectionArgs args;
  final MovieListStatus status;
  final List<Movie> movies;
  final String query;
  final MovieSortOption sortOption;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final Failure? failure;

  bool get hasQuery => query.trim().isNotEmpty;

  bool get canLoadMore => !args.isLibrarySection && currentPage < totalPages;

  String get title => args.title;

  String get heroTagPrefix {
    final homeSection = args.homeSection;
    if (homeSection != null) return 'movie-section-${homeSection.name}';
    return 'movie-section-${args.libraryListType!.value}';
  }

  List<Movie> get visibleMovies {
    final normalizedQuery = query.trim().toLowerCase();
    final filtered = normalizedQuery.isEmpty
        ? movies
        : movies.where((movie) {
            return movie.title.toLowerCase().contains(normalizedQuery);
          }).toList();

    return _sortedMovies(filtered, sortOption);
  }

  MovieSectionState copyWith({
    MovieListStatus? status,
    List<Movie>? movies,
    String? query,
    MovieSortOption? sortOption,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
    Failure? failure,
  }) {
    return MovieSectionState(
      args: args,
      status: status ?? this.status,
      movies: movies ?? this.movies,
      query: query ?? this.query,
      sortOption: sortOption ?? this.sortOption,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: failure,
    );
  }

  static List<Movie> _sortedMovies(
    Iterable<Movie> movies,
    MovieSortOption mode,
  ) {
    final sorted = [...movies];
    switch (mode) {
      case MovieSortOption.rating:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
      case MovieSortOption.title:
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case MovieSortOption.newest:
        sorted.sort((a, b) => _yearValue(b.year).compareTo(_yearValue(a.year)));
    }
    return sorted;
  }

  static int _yearValue(String year) => int.tryParse(year) ?? 0;

  @override
  List<Object?> get props => [
    args,
    status,
    movies,
    query,
    sortOption,
    currentPage,
    totalPages,
    isLoadingMore,
    failure,
  ];
}

class MovieSectionCubit extends Cubit<MovieSectionState> {
  MovieSectionCubit(
    this._homeRepository,
    MovieSectionArgs args, [
    this._libraryRepository,
  ])
    : super(MovieSectionState(args: args));

  final HomeRepository _homeRepository;
  final LibraryRepository? _libraryRepository;

  Future<void> loadInitial() async {
    emit(
      state.copyWith(
        status: MovieListStatus.loading,
        movies: const [],
        currentPage: 0,
        totalPages: 1,
        isLoadingMore: false,
        failure: null,
      ),
    );

    final homeSection = state.args.homeSection;
    if (homeSection == null) {
      await _loadLibrarySection();
      return;
    }

    final result = await _homeRepository.fetchMovieSection(
      section: homeSection,
      page: 1,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: MovieListStatus.failure,
          currentPage: 0,
          totalPages: 1,
          failure: failure,
        ),
      ),
      (page) => emit(
        state.copyWith(
          status: MovieListStatus.loaded,
          movies: page.movies,
          currentPage: page.page,
          totalPages: page.totalPages,
          failure: null,
        ),
      ),
    );
  }

  void setQuery(String value) {
    emit(state.copyWith(query: value.trim(), failure: null));
  }

  void clearQuery() {
    emit(state.copyWith(query: '', failure: null));
  }

  void selectSortOption(MovieSortOption mode) {
    if (mode == state.sortOption) return;
    emit(state.copyWith(sortOption: mode, failure: null));
  }

  Future<void> loadNextPage() async {
    if (state.status != MovieListStatus.loaded ||
        state.isLoadingMore ||
        !state.canLoadMore) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true, failure: null));

    final homeSection = state.args.homeSection;
    if (homeSection == null) return;

    final result = await _homeRepository.fetchMovieSection(
      section: homeSection,
      page: state.currentPage + 1,
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

  Future<void> _loadLibrarySection() async {
    final type = state.args.libraryListType;
    if (type == null) return;

    final repository = _libraryRepository;
    if (repository == null) {
      emit(
        state.copyWith(
          status: MovieListStatus.failure,
          failure: const CacheFailure(message: 'Library is unavailable.'),
        ),
      );
      return;
    }

    final result = await repository.movies(type);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: MovieListStatus.failure,
          currentPage: 0,
          totalPages: 1,
          failure: failure,
        ),
      ),
      (movies) => emit(
        state.copyWith(
          status: MovieListStatus.loaded,
          movies: movies,
          currentPage: 1,
          totalPages: 1,
          failure: null,
        ),
      ),
    );
  }
}
