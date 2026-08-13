import 'dart:async';

import 'package:cinmovies_app/core/error/app_error.dart';
import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';
import 'package:cinmovies_app/features/library/domain/entities/library_movie_entry.dart';
import 'package:cinmovies_app/features/library/presentation/model/library_movie_model.dart';
import 'package:cinmovies_app/features/library/presentation/model/library_tab_model.dart';
import 'package:cinmovies_app/features/trailers/data/trailer_history_repository.dart';
import 'package:cinmovies_app/features/trailers/domain/entities/trailer_history_entry.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum LibraryStatus { initial, loading, loaded, failure }

class LibraryState extends Equatable {
  const LibraryState({
    this.status = LibraryStatus.initial,
    this.tabs = _emptyTabs,
    this.history = const [],
    this.failure,
  });

  static const _emptyTabs = [
    LibraryTabModel(
      label: 'History',
      type: 'trailer_history',
      emptyLabel: 'No trailer history yet',
      movies: [],
      hasMore: false,
    ),
    LibraryTabModel(
      label: 'Watchlist',
      type: 'watchlist',
      emptyLabel: 'Your watchlist is empty',
      movies: [],
    ),
    LibraryTabModel(
      label: 'Favorites',
      type: 'favorite',
      emptyLabel: 'No favorite movies yet',
      movies: [],
    ),
  ];

  final LibraryStatus status;
  final List<LibraryTabModel> tabs;
  final List<TrailerHistoryEntry> history;
  final AppError? failure;

  LibraryState copyWith({
    LibraryStatus? status,
    List<LibraryTabModel>? tabs,
    List<TrailerHistoryEntry>? history,
    AppError? failure,
    bool clearFailure = false,
  }) {
    return LibraryState(
      status: status ?? this.status,
      tabs: tabs ?? this.tabs,
      history: history ?? this.history,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [status, tabs, history, failure];
}

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(this._repository, this._trailerHistoryRepository)
    : super(const LibraryState());

  static const pageSize = 20;

  final LibraryRepository _repository;
  final TrailerHistoryRepository _trailerHistoryRepository;
  StreamSubscription<List<TrailerHistoryEntry>>? _historySubscription;

  Future<void> load() async {
    _watchTrailerHistory();
    emit(state.copyWith(status: LibraryStatus.loading, clearFailure: true));
    final results = await Future.wait([
      _repository.movieEntriesPage(
        type: UserMovieListType.watchlist,
        page: 0,
        pageSize: pageSize,
      ),
      _repository.movieEntriesPage(
        type: UserMovieListType.favorite,
        page: 0,
        pageSize: pageSize,
      ),
    ]);

    for (final result in results) {
      final error = result.errorOrNull;
      if (error != null) {
        emit(state.copyWith(status: LibraryStatus.failure, failure: error));
        return;
      }
    }

    emit(
      state.copyWith(
        status: LibraryStatus.loaded,
        tabs: _buildTabsFromEntries(
          results.map((result) => result.getOrElse(() => const [])).toList(),
        ),
        clearFailure: true,
      ),
    );
  }

  void _watchTrailerHistory() {
    if (_historySubscription != null) return;
    _historySubscription = _trailerHistoryRepository.watchHistory().listen((
      history,
    ) {
      if (isClosed) return;
      emit(state.copyWith(history: history));
    });
  }

  List<LibraryTabModel> _buildTabsFromEntries(
    List<List<LibraryMovieEntry>> entries,
  ) {
    return [
      LibraryTabModel(
        label: 'History',
        type: 'trailer_history',
        emptyLabel: 'No trailer history yet',
        hasMore: false,
        movies: const [],
      ),
      LibraryTabModel(
        label: 'Watchlist',
        type: UserMovieListType.watchlist.value,
        emptyLabel: 'Your watchlist is empty',
        hasMore: entries[0].length == pageSize,
        movies: entries[0]
            .map((entry) => _movieFromEntry(entry, 'Saved for later', 0))
            .toList(),
      ),
      LibraryTabModel(
        label: 'Favorites',
        type: UserMovieListType.favorite.value,
        emptyLabel: 'No favorite movies yet',
        hasMore: entries[1].length == pageSize,
        movies: entries[1]
            .map((entry) => _movieFromEntry(entry, 'Favorite', 1))
            .toList(),
      ),
    ];
  }

  LibraryMovieModel _movieFromEntry(
    LibraryMovieEntry entry,
    String status,
    double progress,
  ) {
    final movie = entry.movie;

    return LibraryMovieModel(
      movieId: entry.storedMovieId,
      movie: movie,
      title: movie.title,
      imageAsset: movie.imageAsset,
      genre: 'Movie',
      year: movie.year,
      duration: movie.duration,
      status: status,
      progress: progress,
      actionIcon: _iconForStatus(status),
    );
  }

  Future<void> loadNextPage(String typeValue) async {
    final tabIndex = state.tabs.indexWhere((tab) => tab.type == typeValue);
    if (tabIndex == -1) return;

    final tab = state.tabs[tabIndex];
    final type = _typeFromValue(typeValue);
    if (type == null || tab.isLoadingMore || !tab.hasMore) return;

    final loadingTabs = [...state.tabs];
    loadingTabs[tabIndex] = tab.copyWith(isLoadingMore: true);
    emit(state.copyWith(tabs: loadingTabs, clearFailure: true));

    final nextPage = tab.page + 1;
    final result = await _repository.movieEntriesPage(
      type: type,
      page: nextPage,
      pageSize: pageSize,
    );
    if (isClosed) return;

    result.when(
      onSuccess: (entries) {
        final currentTabs = [...state.tabs];
        final currentIndex = currentTabs.indexWhere(
          (item) => item.type == typeValue,
        );
        if (currentIndex == -1) return;

        final currentTab = currentTabs[currentIndex];
        final existingIds = currentTab.movies
            .map((movie) => movie.movieId)
            .toSet();
        final newMovies = entries
            .map(
              (entry) => _movieFromEntry(
                entry,
                _statusForType(type),
                _progressForType(type),
              ),
            )
            .where((movie) => !existingIds.contains(movie.movieId))
            .toList();

        currentTabs[currentIndex] = currentTab.copyWith(
          movies: [...currentTab.movies, ...newMovies],
          page: nextPage,
          hasMore: entries.length == pageSize,
          isLoadingMore: false,
        );
        emit(state.copyWith(tabs: currentTabs, clearFailure: true));
      },
      onFailure: (error) {
        final tabs = [...state.tabs];
        final currentIndex = tabs.indexWhere((item) => item.type == typeValue);
        if (currentIndex == -1) return;
        tabs[currentIndex] = tabs[currentIndex].copyWith(isLoadingMore: false);
        emit(state.copyWith(tabs: tabs, failure: error));
      },
    );
  }

  Future<bool> removeFromList(LibraryMovieModel movie, String typeValue) async {
    final type = _typeFromValue(typeValue);
    if (type == null || movie.movieId.trim().isEmpty) return false;

    final previousTabs = state.tabs;
    final nextTabs = previousTabs
        .map(
          (tab) => tab.type == typeValue
              ? LibraryTabModel(
                  movies: tab.movies
                      .where((item) => item.movieId != movie.movieId)
                      .toList(),
                  label: tab.label,
                  type: tab.type,
                  emptyLabel: tab.emptyLabel,
                  page: tab.page,
                  hasMore: tab.hasMore,
                  isLoadingMore: tab.isLoadingMore,
                )
              : tab,
        )
        .toList();
    emit(state.copyWith(tabs: nextTabs, clearFailure: true));

    final result = await _repository.removeMovieIdFromList(
      movieId: movie.movieId,
      type: type,
    );

    return result.when(
      onSuccess: (_) => true,
      onFailure: (error) {
        emit(state.copyWith(tabs: previousTabs, failure: error));
        return false;
      },
    );
  }

  Future<bool> removeFromHistory(TrailerHistoryEntry entry) async {
    if (entry.videoKey.trim().isEmpty) return false;

    final result = await _trailerHistoryRepository.remove(entry.videoKey);
    return result.isSuccess;
  }

  String _statusForType(UserMovieListType type) {
    return switch (type) {
      UserMovieListType.watched => 'Continue watching',
      UserMovieListType.watchlist => 'Saved for later',
      UserMovieListType.favorite => 'Favorite',
    };
  }

  double _progressForType(UserMovieListType type) {
    return switch (type) {
      UserMovieListType.watchlist => 0,
      _ => 1,
    };
  }

  UserMovieListType? _typeFromValue(String value) {
    for (final type in UserMovieListType.values) {
      if (type.value == value) return type;
    }
    return null;
  }

  IconData _iconForStatus(String status) {
    return switch (status) {
      'Saved for later' => Icons.bookmark_rounded,
      'Favorite' => Icons.favorite_rounded,
      _ => Icons.play_arrow_rounded,
    };
  }

  @override
  Future<void> close() async {
    await _historySubscription?.cancel();
    return super.close();
  }
}
