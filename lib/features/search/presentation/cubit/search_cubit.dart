import 'dart:async';

import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/core/local/hive_cache_service.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/search/data/search_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchState extends Equatable {
  const SearchState({
    this.query = '',
    this.status = SearchStatus.initial,
    this.results = const [],
    this.currentPage = 0,
    this.totalPages = 1,
    this.isLoadingMore = false,
    this.recentSearches = const [],
    this.sortMode = SearchSortMode.rating,
    this.failure,
  });

  final String query;
  final SearchStatus status;
  final List<Movie> results;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final List<String> recentSearches;
  final SearchSortMode sortMode;
  final Failure? failure;

  bool get hasQuery => query.trim().isNotEmpty;

  bool get canLoadMore => currentPage < totalPages;

  SearchState copyWith({
    String? query,
    SearchStatus? status,
    List<Movie>? results,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
    List<String>? recentSearches,
    SearchSortMode? sortMode,
    Failure? failure,
  }) {
    return SearchState(
      query: query ?? this.query,
      status: status ?? this.status,
      results: results ?? this.results,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      recentSearches: recentSearches ?? this.recentSearches,
      sortMode: sortMode ?? this.sortMode,
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
    sortMode,
    failure,
  ];
}

enum SearchStatus { initial, loading, loaded, failure }

enum SearchSortMode {
  rating('Rating'),
  title('A-Z'),
  time('Time');

  const SearchSortMode(this.label);

  final String label;
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
          status: SearchStatus.initial,
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
        status: SearchStatus.loading,
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

  void clear() => setQuery('');

  Future<void> submit(String value) async {
    final query = value.trim();
    if (query.isEmpty) return;

    await _saveRecentSearch(query);
    _debounceTimer?.cancel();
    final requestToken = ++_requestToken;
    emit(
      state.copyWith(
        query: query,
        status: SearchStatus.loading,
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

  void setSortMode(SearchSortMode mode) {
    if (mode == state.sortMode) return;
    emit(
      state.copyWith(
        sortMode: mode,
        results: _sortedMovies(state.results, mode),
      ),
    );
  }

  Future<void> loadNextPage() async {
    if (state.status != SearchStatus.loaded ||
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

    result.fold(
      (failure) => emit(
        state.copyWith(isLoadingMore: false, failure: failure),
      ),
      (page) => emit(
        state.copyWith(
          status: SearchStatus.loaded,
          results: _sortedMovies(
            [...state.results, ...page.movies],
            state.sortMode,
          ),
          currentPage: page.page,
          totalPages: page.totalPages,
          isLoadingMore: false,
          failure: null,
        ),
      ),
    );
  }

  Future<void> _searchFirstPage(String query, int requestToken) async {
    final result = await _repository.searchMovies(query: query, page: 1);
    if (requestToken != _requestToken || query != state.query) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SearchStatus.failure,
          results: const [],
          currentPage: 0,
          totalPages: 1,
          isLoadingMore: false,
          failure: failure,
        ),
      ),
      (page) => emit(
        state.copyWith(
          status: SearchStatus.loaded,
          results: _sortedMovies(page.movies, state.sortMode),
          currentPage: page.page,
          totalPages: page.totalPages,
          isLoadingMore: false,
          failure: null,
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

  List<Movie> _sortedMovies(
    List<Movie> movies,
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

  int _yearValue(String year) => int.tryParse(year) ?? 0;

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
