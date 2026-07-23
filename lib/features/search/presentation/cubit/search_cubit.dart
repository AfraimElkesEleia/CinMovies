import 'dart:async';

import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/core/local/hive_cache_service.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
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
    this.failure,
  });

  final String query;
  final SearchStatus status;
  final List<HomeMovieModel> results;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final List<String> recentSearches;
  final Failure? failure;

  bool get hasQuery => query.trim().isNotEmpty;

  bool get canLoadMore => currentPage < totalPages;

  SearchState copyWith({
    String? query,
    SearchStatus? status,
    List<HomeMovieModel>? results,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
    List<String>? recentSearches,
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
    failure,
  ];
}

enum SearchStatus { initial, loading, loaded, failure }

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
          results: [...state.results, ...page.movies],
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
          results: page.movies,
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

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
