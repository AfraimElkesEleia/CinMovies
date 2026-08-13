import 'dart:async';

import 'package:cinmovies_app/core/error/app_error.dart';
import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/features/home/data/home_repository.dart';
import 'package:cinmovies_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/preferences/data/genre_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('emits cached Home data before replacing it with fresh data', () async {
    final cachedAt = DateTime.utc(2026, 7, 20);
    final repository = _FakeHomeRepository(
      cached: CachedHomeFeed(
        data: HomeFeedData(
          popularMovies: [_movie('1', 'Cached Popular')],
          upcomingMovies: [_movie('2', 'Cached Upcoming')],
        ),
        cachedAt: cachedAt,
      ),
      remote: Success(
        HomeFeedData(
          popularMovies: [_movie('3', 'Fresh Popular')],
          upcomingMovies: [_movie('4', 'Fresh Upcoming')],
        ),
      ),
    );
    final cubit = HomeCubit(repository);
    addTearDown(cubit.close);
    final states = <HomeState>[];
    final subscription = cubit.stream.listen(states.add);
    addTearDown(subscription.cancel);

    await cubit.loadMovies();
    await Future<void>.delayed(Duration.zero);

    expect(states, hasLength(2));
    expect(states.first.popularMovies.single.title, 'Cached Popular');
    expect(states.first.isFromCache, isTrue);
    expect(states.first.isRefreshing, isTrue);
    expect(states.first.cachedAt, cachedAt);
    expect(states.last.popularMovies.single.title, 'Fresh Popular');
    expect(states.last.isFromCache, isFalse);
    expect(states.last.isRefreshing, isFalse);
  });

  test(
    'retains cached Home data and failure when refresh is offline',
    () async {
      final repository = _FakeHomeRepository(
        cached: CachedHomeFeed(
          data: HomeFeedData(
            popularMovies: [_movie('1', 'Cached Popular')],
            upcomingMovies: const [],
          ),
          cachedAt: DateTime.utc(2026, 7, 20),
        ),
        remote: const Failure(NetworkAppError(message: 'No connection')),
      );
      final cubit = HomeCubit(repository);
      addTearDown(cubit.close);

      await cubit.loadMovies();

      expect(cubit.state.status, HomeStatus.loaded);
      expect(cubit.state.popularMovies.single.title, 'Cached Popular');
      expect(cubit.state.isFromCache, isTrue);
      expect(cubit.state.isRefreshing, isFalse);
      expect(cubit.state.failure?.message, 'No connection');
    },
  );

  test(
    'uses failure state when neither cache nor network is available',
    () async {
      final cubit = HomeCubit(
        _FakeHomeRepository(
          remote: const Failure(NetworkAppError(message: 'No connection')),
        ),
      );
      addTearDown(cubit.close);

      await cubit.loadMovies();

      expect(cubit.state.status, HomeStatus.failure);
      expect(cubit.state.popularMovies, isEmpty);
      expect(cubit.state.isFromCache, isFalse);
    },
  );

  test('loads For You from normalized cached favorite genres', () async {
    final repository = _FakeHomeRepository(
      remote: Success(
        HomeFeedData(
          popularMovies: [_movie('1', 'Popular')],
          upcomingMovies: const [],
        ),
      ),
      forYouHandler: (genreIds) => Success(
        MovieSectionPage(
          movies: [_movie('2', 'Personalized')],
          page: 1,
          totalPages: 2,
        ),
      ),
    );
    final preferences = _FakeGenrePreferencesRepository(
      cached: {'Action', 'Sci Fi', 'science fiction'},
    );
    final cubit = HomeCubit(repository, preferences);
    addTearDown(cubit.close);
    addTearDown(preferences.close);

    await cubit.loadMovies();
    await Future<void>.delayed(Duration.zero);

    expect(repository.forYouRequests, [
      [28, 878],
    ]);
    expect(cubit.state.favoriteGenreIds, [28, 878]);
    expect(cubit.state.forYouMovies.single.title, 'Personalized');
    expect(cubit.state.popularMovies.single.title, 'Popular');
  });

  test(
    'keeps generic and cached personalized movies on For You failure',
    () async {
      final repository = _FakeHomeRepository(
        remote: Success(
          HomeFeedData(
            popularMovies: [_movie('1', 'Popular')],
            upcomingMovies: const [],
          ),
        ),
        cachedForYou: CachedMovieSection(
          page: MovieSectionPage(
            movies: [_movie('2', 'Cached For You')],
            page: 1,
            totalPages: 1,
          ),
          cachedAt: DateTime.utc(2026, 7, 20),
        ),
        forYouHandler: (_) =>
            const Failure(NetworkAppError(message: 'No connection')),
      );
      final preferences = _FakeGenrePreferencesRepository(cached: {'Drama'});
      final cubit = HomeCubit(repository, preferences);
      addTearDown(cubit.close);
      addTearDown(preferences.close);

      await cubit.loadMovies();

      expect(cubit.state.status, HomeStatus.loaded);
      expect(cubit.state.popularMovies.single.title, 'Popular');
      expect(cubit.state.forYouMovies.single.title, 'Cached For You');
      expect(cubit.state.failure, isNull);
    },
  );

  test('refreshes For You when scoped favorite genres change', () async {
    final repository = _FakeHomeRepository(
      remote: Success(
        HomeFeedData(
          popularMovies: [_movie('1', 'Popular')],
          upcomingMovies: const [],
        ),
      ),
      forYouHandler: (genreIds) => Success(
        MovieSectionPage(
          movies: [_movie('${genreIds.first}', 'For ${genreIds.first}')],
          page: 1,
          totalPages: 1,
        ),
      ),
    );
    final preferences = _FakeGenrePreferencesRepository(cached: {'Action'});
    final cubit = HomeCubit(repository, preferences);
    addTearDown(cubit.close);
    addTearDown(preferences.close);

    await cubit.loadMovies();
    preferences.emit({'Comedy'});
    await Future<void>.delayed(Duration.zero);

    expect(repository.forYouRequests, [
      [28],
      [35],
    ]);
    expect(cubit.state.favoriteGenreIds, [35]);
    expect(cubit.state.forYouMovies.single.title, 'For 35');
  });

  test(
    'does not personalize when no authenticated preference scope exists',
    () async {
      final repository = _FakeHomeRepository(
        remote: Success(
          HomeFeedData(
            popularMovies: [_movie('1', 'Popular')],
            upcomingMovies: const [],
          ),
        ),
      );
      final preferences = _FakeGenrePreferencesRepository(scopeId: null);
      final cubit = HomeCubit(repository, preferences);
      addTearDown(cubit.close);
      addTearDown(preferences.close);

      await cubit.loadMovies();

      expect(repository.forYouRequests, isEmpty);
      expect(cubit.state.forYouMovies, isEmpty);
    },
  );
}

class _FakeHomeRepository extends Fake implements HomeRepository {
  _FakeHomeRepository({
    this.cached,
    required this.remote,
    this.cachedForYou,
    this.forYouHandler,
  });

  final CachedHomeFeed? cached;
  final Result<HomeFeedData> remote;
  final CachedMovieSection? cachedForYou;
  final Result<MovieSectionPage> Function(List<int> genreIds)? forYouHandler;
  final List<List<int>> forYouRequests = [];

  @override
  CachedHomeFeed? readCachedHomeMovies() => cached;

  @override
  Future<Result<HomeFeedData>> fetchHomeMovies() async => remote;

  @override
  CachedMovieSection? readCachedForYouMovies({
    required String scopeId,
    required List<int> genreIds,
  }) {
    return cachedForYou;
  }

  @override
  Future<Result<MovieSectionPage>> fetchForYouMovies({
    required List<int> genreIds,
    required int page,
    String? cacheScope,
  }) async {
    forYouRequests.add([...genreIds]);
    return forYouHandler?.call(genreIds) ??
        const Success(MovieSectionPage(movies: [], page: 1, totalPages: 1));
  }
}

class _FakeGenrePreferencesRepository implements GenrePreferencesRepository {
  _FakeGenrePreferencesRepository({
    this.scopeId = 'user-1',
    this.cached = const {},
    Set<String>? remote,
  }) : remote = remote ?? cached;

  final String? scopeId;
  Set<String> cached;
  Set<String> remote;
  final StreamController<Set<String>> _controller =
      StreamController<Set<String>>.broadcast();

  @override
  String? get userScopeId => scopeId;

  @override
  Set<String> cachedFavoriteGenres() => {...cached};

  @override
  Future<Result<Set<String>>> loadFavoriteGenres() async =>
      Success({...remote});

  @override
  Future<Result<void>> saveFavoriteGenres(Set<String> genreNames) async {
    cached = {...genreNames};
    remote = {...genreNames};
    _controller.add({...genreNames});
    return const Success(null);
  }

  @override
  Future<Result<void>> syncCachedFavoriteGenres() async => const Success(null);

  @override
  Stream<Set<String>> watchFavoriteGenres() => _controller.stream;

  void emit(Set<String> genres) {
    cached = {...genres};
    _controller.add({...genres});
  }

  Future<void> close() => _controller.close();
}

Movie _movie(String id, String title) {
  return Movie(
    id: id,
    title: title,
    imageAsset: 'assets/images/movie_ex1.jpg',
    genres: const ['Drama'],
    rating: 7,
    year: '2026',
    duration: '2h',
    ageRating: 'PG-13',
    synopsis: 'Synopsis',
    director: 'Director',
    votes: '1K',
    cast: const [],
    reviews: const [],
  );
}
