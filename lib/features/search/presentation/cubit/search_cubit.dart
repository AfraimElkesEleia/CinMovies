import 'dart:async';

import 'package:cinmovies_app/core/error/app_error.dart';
import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/core/local/hive_cache_service.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/movies/presentation/model/movie_list_options.dart';
import 'package:cinmovies_app/features/search/data/search_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchState extends Equatable {
  const SearchState({
    this.query = '',
    this.status = MovieListStatus.initial,
    this.results = const [],
    this.currentPage = 0,
    this.totalPages = 1,
    this.isLoadingMore = false,
    this.recentSearches = const [],
    this.sortOption = MovieSortOption.rating,
    this.failure,
  });

  final String query;
  final MovieListStatus status;
  final List<Movie> results;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final List<String> recentSearches;
  final MovieSortOption sortOption;
  final AppError? failure;

  bool get hasQuery => query.trim().isNotEmpty;

  bool get canLoadMore => currentPage < totalPages;

  SearchState copyWith({
    String? query,
    MovieListStatus? status,
    List<Movie>? results,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
    List<String>? recentSearches,
    MovieSortOption? sortOption,
    AppError? failure,
  }) {
    return SearchState(
      query: query ?? this.query,
      status: status ?? this.status,
      results: results ?? this.results,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      recentSearches: recentSearches ?? this.recentSearches,
      sortOption: sortOption ?? this.sortOption,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [
    query,
    status,
    results,
    currentPage,
    totalPages,
    isLoadingMore,
    recentSearches,
    sortOption,
    failure,
  ];
}

class SearchCubit extends Cubit<SearchState> {
  SearchCubit(
    this._repository,
    this._cache, {
    this._debounceDuration = const Duration(milliseconds: 400),
  }) : super(SearchState(recentSearches: _cache.getRecentSearches()));

  final SearchRepository _repository;
  final HiveCacheService _cache;
  final Duration _debounceDuration;

  Timer? _debounceTimer;
  int _requestToken = 0;

  void setQuery(String value) {
    final query = value.trim();
    _debounceTimer?.cancel();
    final requestToken = ++_requestToken;

    if (query.isEmpty) {
      emit(
        state.copyWith(
          query: '',
          status: MovieListStatus.initial,
          results: const [],
          currentPage: 0,
          totalPages: 1,
          isLoadingMore: false,
          failure: null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        query: query,
        status: MovieListStatus.loading,
        results: const [],
        currentPage: 0,
        totalPages: 1,
        isLoadingMore: false,
        failure: null,
      ),
    );

    _debounceTimer = Timer(_debounceDuration, () {
      _searchFirstPage(query, requestToken);
    });
  }

  void clearQuery() => setQuery('');

  Future<void> submitQuery(String value) async {
    final query = value.trim();
    if (query.isEmpty) return;

    await _saveRecentSearch(query);
    _debounceTimer?.cancel();
    final requestToken = ++_requestToken;
    emit(
      state.copyWith(
        query: query,
        status: MovieListStatus.loading,
        results: const [],
        currentPage: 0,
        totalPages: 1,
        isLoadingMore: false,
        failure: null,
      ),
    );
    await _searchFirstPage(query, requestToken);
  }

  Future<void> saveCurrentQuery() async {
    await _saveRecentSearch(state.query);
  }

  Future<void> deleteRecentSearch(String value) async {
    await _cache.deleteRecentSearch(value);
    emit(state.copyWith(recentSearches: _cache.getRecentSearches()));
  }

  void selectSortOption(MovieSortOption mode) {
    if (mode == state.sortOption) return;
    emit(
      state.copyWith(
        sortOption: mode,
        results: _sortedMovies(state.results, mode),
      ),
    );
  }

  Future<void> loadNextPage() async {
    if (state.status != MovieListStatus.loaded ||
        state.isLoadingMore ||
        !state.canLoadMore ||
        !state.hasQuery) {
      return;
    }

    final query = state.query;
    final requestToken = _requestToken;
    emit(state.copyWith(isLoadingMore: true, failure: null));

    final result = await _repository.searchMovies(
      query: query,
      page: state.currentPage + 1,
    );

    if (requestToken != _requestToken || query != state.query) return;

    result.when(
      onSuccess: (page) => emit(
        state.copyWith(
          status: MovieListStatus.loaded,
          results: _sortedMovies([
            ...state.results,
            ...page.movies,
          ], state.sortOption),
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

  Future<void> _searchFirstPage(String query, int requestToken) async {
    final result = await _repository.searchMovies(query: query, page: 1);
    if (requestToken != _requestToken || query != state.query) return;

    result.when(
      onSuccess: (page) => emit(
        state.copyWith(
          status: MovieListStatus.loaded,
          results: _sortedMovies(page.movies, state.sortOption),
          currentPage: page.page,
          totalPages: page.totalPages,
          isLoadingMore: false,
          failure: null,
        ),
      ),
      onFailure: (error) => emit(
        state.copyWith(
          status: MovieListStatus.failure,
          results: const [],
          currentPage: 0,
          totalPages: 1,
          isLoadingMore: false,
          failure: error,
        ),
      ),
    );
  }

  Future<void> _saveRecentSearch(String value) async {
    final query = value.trim();
    if (query.isEmpty) return;
    await _cache.saveRecentSearch(query);
    emit(state.copyWith(recentSearches: _cache.getRecentSearches()));
  }

  List<Movie> _sortedMovies(List<Movie> movies, MovieSortOption mode) {
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

  int _yearValue(String year) => int.tryParse(year) ?? 0;

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
