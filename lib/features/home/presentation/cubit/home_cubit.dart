import 'dart:async';

import 'package:cinmovies_app/core/error/app_error.dart';
import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/features/home/data/home_repository.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/preferences/data/genre_preferences_repository.dart';
import 'package:cinmovies_app/features/preferences/domain/movie_genre_option.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeState extends Equatable {
  const HomeState({
    required this.status,
    required this.popularMovies,
    required this.upcomingMovies,
    this.forYouMovies = const [],
    this.favoriteGenreIds = const [],
    this.isFromCache = false,
    this.isRefreshing = false,
    this.cachedAt,
    this.failure,
  });

  const HomeState.initial()
    : status = HomeStatus.initial,
      popularMovies = const [],
      upcomingMovies = const [],
      forYouMovies = const [],
      favoriteGenreIds = const [],
      isFromCache = false,
      isRefreshing = false,
      cachedAt = null,
      failure = null;

  final HomeStatus status;
  final List<Movie> popularMovies;
  final List<Movie> upcomingMovies;
  final List<Movie> forYouMovies;
  final List<int> favoriteGenreIds;
  final bool isFromCache;
  final bool isRefreshing;
  final DateTime? cachedAt;
  final AppError? failure;

  List<Movie> get carouselMovies => popularMovies.take(5).toList();

  HomeState copyWith({
    HomeStatus? status,
    List<Movie>? popularMovies,
    List<Movie>? upcomingMovies,
    List<Movie>? forYouMovies,
    List<int>? favoriteGenreIds,
    bool? isFromCache,
    bool? isRefreshing,
    DateTime? cachedAt,
    AppError? failure,
    bool clearFailure = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      popularMovies: popularMovies ?? this.popularMovies,
      upcomingMovies: upcomingMovies ?? this.upcomingMovies,
      forYouMovies: forYouMovies ?? this.forYouMovies,
      favoriteGenreIds: favoriteGenreIds ?? this.favoriteGenreIds,
      isFromCache: isFromCache ?? this.isFromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      cachedAt: cachedAt ?? this.cachedAt,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    popularMovies,
    upcomingMovies,
    forYouMovies,
    favoriteGenreIds,
    isFromCache,
    isRefreshing,
    cachedAt,
    failure,
  ];
}

enum HomeStatus { initial, loading, loaded, failure }

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repository, [this._preferencesRepository])
    : super(const HomeState.initial());

  final HomeRepository _repository;
  final GenrePreferencesRepository? _preferencesRepository;
  bool _isRefreshInFlight = false;
  String? _preferenceScopeId;
  String _favoriteGenreSignature = '';
  StreamSubscription<Set<String>>? _preferenceSubscription;
  final Set<String> _forYouRequestsInFlight = {};

  Future<void> loadMovies() async {
    if (_isRefreshInFlight) return;
    _isRefreshInFlight = true;

    try {
      _startPreferenceTracking();
      final hasVisibleMovies =
          state.popularMovies.isNotEmpty || state.upcomingMovies.isNotEmpty;
      if (hasVisibleMovies) {
        emit(
          state.copyWith(
            status: HomeStatus.loaded,
            isRefreshing: true,
            clearFailure: true,
          ),
        );
      } else {
        final cached = _repository.readCachedHomeMovies();
        if (cached == null) {
          emit(
            state.copyWith(
              status: HomeStatus.loading,
              isRefreshing: true,
              clearFailure: true,
            ),
          );
        } else {
          emit(
            HomeState(
              status: HomeStatus.loaded,
              popularMovies: cached.data.popularMovies,
              upcomingMovies: cached.data.upcomingMovies,
              forYouMovies: state.forYouMovies,
              favoriteGenreIds: state.favoriteGenreIds,
              isFromCache: true,
              isRefreshing: true,
              cachedAt: cached.cachedAt,
            ),
          );
        }
      }

      final result = await _repository.fetchHomeMovies();
      if (isClosed) return;

      result.when(
        onSuccess: (movies) => emit(
          HomeState(
            status: HomeStatus.loaded,
            popularMovies: movies.popularMovies,
            upcomingMovies: movies.upcomingMovies,
            forYouMovies: state.forYouMovies,
            favoriteGenreIds: state.favoriteGenreIds,
            isFromCache: false,
            isRefreshing: false,
            cachedAt: DateTime.now().toUtc(),
          ),
        ),
        onFailure: (error) {
          final hasFallback =
              state.popularMovies.isNotEmpty || state.upcomingMovies.isNotEmpty;
          emit(
            state.copyWith(
              status: hasFallback ? HomeStatus.loaded : HomeStatus.failure,
              isFromCache: hasFallback,
              isRefreshing: false,
              failure: error,
            ),
          );
        },
      );

      if (!isClosed) {
        await _refreshForYou();
      }
      if (!isClosed) {
        unawaited(_refreshFavoriteGenresFromRemote());
      }
    } finally {
      _isRefreshInFlight = false;
    }
  }

  void _startPreferenceTracking() {
    final repository = _preferencesRepository;
    final scopeId = repository?.userScopeId;
    if (repository == null || scopeId == null || scopeId.isEmpty) return;
    if (_preferenceScopeId == scopeId && _preferenceSubscription != null) {
      return;
    }

    _preferenceScopeId = scopeId;
    _setFavoriteGenres(repository.cachedFavoriteGenres(), refresh: false);
    unawaited(_preferenceSubscription?.cancel());
    _preferenceSubscription = repository.watchFavoriteGenres().listen(
      (genres) => _setFavoriteGenres(genres, refresh: true),
    );
  }

  void _setFavoriteGenres(Set<String> genres, {required bool refresh}) {
    if (isClosed) return;
    final genreIds = normalizeFavoriteGenreIds(genres);
    final signature = genreIds.join('|');
    if (signature == _favoriteGenreSignature) return;

    _favoriteGenreSignature = signature;
    emit(state.copyWith(favoriteGenreIds: genreIds, forYouMovies: const []));
    if (refresh) unawaited(_refreshForYou());
  }

  Future<void> _refreshFavoriteGenresFromRemote() async {
    final repository = _preferencesRepository;
    if (repository == null || _preferenceScopeId == null) return;
    final result = await repository.loadFavoriteGenres();
    if (isClosed) return;
    result.when(
      onSuccess: (genres) => _setFavoriteGenres(genres, refresh: true),
      onFailure: (_) {
        // Scoped local preferences remain usable while Supabase is unavailable.
      },
    );
  }

  Future<void> _refreshForYou() async {
    final scopeId = _preferenceScopeId;
    final genreIds = [...state.favoriteGenreIds];
    final signature = genreIds.join('|');
    if (scopeId == null || genreIds.isEmpty || signature.isEmpty) return;

    final requestKey = '$scopeId::$signature';
    if (!_forYouRequestsInFlight.add(requestKey)) return;

    try {
      if (state.forYouMovies.isEmpty) {
        final cached = _repository.readCachedForYouMovies(
          scopeId: scopeId,
          genreIds: genreIds,
        );
        if (cached != null &&
            !isClosed &&
            signature == _favoriteGenreSignature) {
          emit(state.copyWith(forYouMovies: cached.page.movies));
        }
      }

      final result = await _repository.fetchForYouMovies(
        genreIds: genreIds,
        page: 1,
        cacheScope: scopeId,
      );
      if (isClosed || signature != _favoriteGenreSignature) return;

      result.when(
        onSuccess: (page) => emit(state.copyWith(forYouMovies: page.movies)),
        onFailure: (_) {},
      );
    } finally {
      _forYouRequestsInFlight.remove(requestKey);
    }
  }

  @override
  Future<void> close() async {
    await _preferenceSubscription?.cancel();
    return super.close();
  }
}
