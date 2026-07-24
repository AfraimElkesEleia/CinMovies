import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/features/home/data/home_repository.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/search/presentation/cubit/search_cubit.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MovieSectionState extends Equatable {
  const MovieSectionState({
    required this.section,
    this.status = SearchStatus.initial,
    this.movies = const [],
    this.query = '',
    this.sortMode = SearchSortMode.rating,
    this.currentPage = 0,
    this.totalPages = 1,
    this.isLoadingMore = false,
    this.failure,
  });

  final HomeMovieSection section;
  final SearchStatus status;
  final List<Movie> movies;
  final String query;
  final SearchSortMode sortMode;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final Failure? failure;

  bool get hasQuery => query.trim().isNotEmpty;

  bool get canLoadMore => currentPage < totalPages;

  List<Movie> get visibleMovies {
    final normalizedQuery = query.trim().toLowerCase();
    final filtered = normalizedQuery.isEmpty
        ? movies
        : movies.where((movie) {
            return movie.title.toLowerCase().contains(normalizedQuery);
          }).toList();

    return _sortedMovies(filtered, sortMode);
  }

  MovieSectionState copyWith({
    SearchStatus? status,
    List<Movie>? movies,
    String? query,
    SearchSortMode? sortMode,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
    Failure? failure,
  }) {
    return MovieSectionState(
      section: section,
      status: status ?? this.status,
      movies: movies ?? this.movies,
      query: query ?? this.query,
      sortMode: sortMode ?? this.sortMode,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: failure,
    );
  }

  static List<Movie> _sortedMovies(
    Iterable<Movie> movies,
    SearchSortMode mode,
  ) {
    final sorted = [...movies];
    switch (mode) {
      case SearchSortMode.rating:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
      case SearchSortMode.title:
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case SearchSortMode.time:
        sorted.sort((a, b) => _yearValue(b.year).compareTo(_yearValue(a.year)));
    }
    return sorted;
  }

  static int _yearValue(String year) => int.tryParse(year) ?? 0;

  @override
  List<Object?> get props => [
    section,
    status,
    movies,
    query,
    sortMode,
    currentPage,
    totalPages,
    isLoadingMore,
    failure,
  ];
}

class MovieSectionCubit extends Cubit<MovieSectionState> {
  MovieSectionCubit(this._repository, HomeMovieSection section)
    : super(MovieSectionState(section: section));

  final HomeRepository _repository;

  Future<void> loadInitial() async {
    emit(
      state.copyWith(
        status: SearchStatus.loading,
        movies: const [],
        currentPage: 0,
        totalPages: 1,
        isLoadingMore: false,
        failure: null,
      ),
    );

    final result = await _repository.fetchMovieSection(
      section: state.section,
      page: 1,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SearchStatus.failure,
          currentPage: 0,
          totalPages: 1,
          failure: failure,
        ),
      ),
      (page) => emit(
        state.copyWith(
          status: SearchStatus.loaded,
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

  void setSortMode(SearchSortMode mode) {
    if (mode == state.sortMode) return;
    emit(state.copyWith(sortMode: mode, failure: null));
  }

  Future<void> loadNextPage() async {
    if (state.status != SearchStatus.loaded ||
        state.isLoadingMore ||
        !state.canLoadMore) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true, failure: null));

    final result = await _repository.fetchMovieSection(
      section: state.section,
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
}
