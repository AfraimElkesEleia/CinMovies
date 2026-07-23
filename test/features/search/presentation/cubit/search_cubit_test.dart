import 'dart:io';

import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/core/local/hive_cache_service.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:cinmovies_app/features/search/data/search_repository.dart';
import 'package:cinmovies_app/features/search/presentation/cubit/search_cubit.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late HiveCacheService cache;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('search_cubit_test_');
    Hive.init(tempDir.path);
    cache = HiveCacheService(
      await Hive.openBox<dynamic>('search_${DateTime.now().microsecondsSinceEpoch}'),
      await Hive.openBox<dynamic>('movies_${DateTime.now().microsecondsSinceEpoch}'),
      await Hive.openBox<dynamic>('users_${DateTime.now().microsecondsSinceEpoch}'),
      await Hive.openBox<dynamic>('genres_${DateTime.now().microsecondsSinceEpoch}'),
    );
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('debounced query triggers one search for the latest value', () async {
    final repository = _FakeSearchRepository({
      'avatar:1': SearchMoviesPage(
        movies: [_movie('1', 'Avatar')],
        page: 1,
        totalPages: 1,
      ),
    });
    final cubit = SearchCubit(
      repository,
      cache,
      debounceDuration: const Duration(milliseconds: 10),
    );
    addTearDown(cubit.close);

    cubit.setQuery('ava');
    cubit.setQuery('avatar');
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(repository.requests, ['avatar:1']);
    expect(cubit.state.status, SearchStatus.loaded);
    expect(cubit.state.results.single.title, 'Avatar');
  });

  test('submit stores only the last six recent searches', () async {
    final repository = _FakeSearchRepository(const {});
    final cubit = SearchCubit(repository, cache, debounceDuration: Duration.zero);
    addTearDown(cubit.close);

    for (final query in ['one', 'two', 'three', 'four', 'five', 'six', 'seven']) {
      await cubit.submit(query);
    }

    expect(cubit.state.recentSearches, [
      'seven',
      'six',
      'five',
      'four',
      'three',
      'two',
    ]);
  });

  test('deleteRecentSearch removes a stored query', () async {
    final repository = _FakeSearchRepository(const {});
    final cubit = SearchCubit(repository, cache, debounceDuration: Duration.zero);
    addTearDown(cubit.close);

    await cubit.submit('avatar');
    await cubit.submit('batman');
    await cubit.deleteRecentSearch('avatar');

    expect(cubit.state.recentSearches, ['batman']);
  });

  test('loadNextPage appends results and stops at totalPages', () async {
    final repository = _FakeSearchRepository({
      'batman:1': SearchMoviesPage(
        movies: [_movie('1', 'Batman Begins')],
        page: 1,
        totalPages: 2,
      ),
      'batman:2': SearchMoviesPage(
        movies: [_movie('2', 'The Batman')],
        page: 2,
        totalPages: 2,
      ),
    });
    final cubit = SearchCubit(repository, cache, debounceDuration: Duration.zero);
    addTearDown(cubit.close);

    await cubit.submit('batman');
    await cubit.loadNextPage();
    await cubit.loadNextPage();

    expect(cubit.state.results.map((movie) => movie.title), [
      'Batman Begins',
      'The Batman',
    ]);
    expect(repository.requests, ['batman:1', 'batman:2']);
  });

  test('failed search emits failure state', () async {
    final repository = _FakeSearchRepository(const {}, failures: {'bad:1'});
    final cubit = SearchCubit(repository, cache, debounceDuration: Duration.zero);
    addTearDown(cubit.close);

    await cubit.submit('bad');

    expect(cubit.state.status, SearchStatus.failure);
    expect(cubit.state.failure?.message, 'No connection');
  });
}

class _FakeSearchRepository extends SearchRepository {
  _FakeSearchRepository(this.pages, {this.failures = const {}}) : super(Dio());

  final Map<String, SearchMoviesPage> pages;
  final Set<String> failures;
  final List<String> requests = [];

  @override
  Future<Either<Failure, SearchMoviesPage>> searchMovies({
    required String query,
    required int page,
  }) async {
    final key = '$query:$page';
    requests.add(key);
    if (failures.contains(key)) {
      return const Left(NetworkFailure(message: 'No connection'));
    }
    return Right(
      pages[key] ??
          SearchMoviesPage(
            movies: [_movie('$page', key)],
            page: page,
            totalPages: page,
          ),
    );
  }
}

HomeMovieModel _movie(String id, String title) {
  return HomeMovieModel(
    id: id,
    title: title,
    imageAsset: 'assets/images/movie_ex1.jpg',
    genres: const [],
    rating: 7,
    year: '2026',
    duration: 'N/A',
    ageRating: 'NR',
    synopsis: 'Synopsis',
    director: 'Unknown',
    votes: '1K',
    availability: MovieAvailability.streaming,
    cast: const [],
    reviews: const [],
  );
}
