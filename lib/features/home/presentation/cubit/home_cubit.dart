import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/features/home/data/home_repository.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeState extends Equatable {
  const HomeState({
    required this.status,
    required this.popularMovies,
    required this.upcomingMovies,
    this.isFromCache = false,
    this.isRefreshing = false,
    this.cachedAt,
    this.failure,
  });

  const HomeState.initial()
    : status = HomeStatus.initial,
      popularMovies = const [],
      upcomingMovies = const [],
      isFromCache = false,
      isRefreshing = false,
      cachedAt = null,
      failure = null;

  final HomeStatus status;
  final List<Movie> popularMovies;
  final List<Movie> upcomingMovies;
  final bool isFromCache;
  final bool isRefreshing;
  final DateTime? cachedAt;
  final Failure? failure;

  List<Movie> get carouselMovies => popularMovies.take(5).toList();

  HomeState copyWith({
    HomeStatus? status,
    List<Movie>? popularMovies,
    List<Movie>? upcomingMovies,
    bool? isFromCache,
    bool? isRefreshing,
    DateTime? cachedAt,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      popularMovies: popularMovies ?? this.popularMovies,
      upcomingMovies: upcomingMovies ?? this.upcomingMovies,
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
    isFromCache,
    isRefreshing,
    cachedAt,
    failure,
  ];
}

enum HomeStatus { initial, loading, loaded, failure }

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repository) : super(const HomeState.initial());

  final HomeRepository _repository;
  bool _isRefreshInFlight = false;

  Future<void> loadMovies() async {
    if (_isRefreshInFlight) return;
    _isRefreshInFlight = true;

    try {
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
              isFromCache: true,
              isRefreshing: true,
              cachedAt: cached.cachedAt,
            ),
          );
        }
      }

      final result = await _repository.fetchHomeMovies();
      if (isClosed) return;

      result.fold(
        (failure) {
          final hasFallback =
              state.popularMovies.isNotEmpty ||
              state.upcomingMovies.isNotEmpty;
          emit(
            state.copyWith(
              status: hasFallback ? HomeStatus.loaded : HomeStatus.failure,
              isFromCache: hasFallback,
              isRefreshing: false,
              failure: failure,
            ),
          );
        },
        (movies) => emit(
          HomeState(
            status: HomeStatus.loaded,
            popularMovies: movies.popularMovies,
            upcomingMovies: movies.upcomingMovies,
            isFromCache: false,
            isRefreshing: false,
            cachedAt: DateTime.now().toUtc(),
          ),
        ),
      );
    } finally {
      _isRefreshInFlight = false;
    }
  }
}
