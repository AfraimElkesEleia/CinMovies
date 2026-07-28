import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/features/home/data/home_repository.dart';
import 'package:cinmovies_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
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
      remote: Right(
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

  test('retains cached Home data and failure when refresh is offline', () async {
    final repository = _FakeHomeRepository(
      cached: CachedHomeFeed(
        data: HomeFeedData(
          popularMovies: [_movie('1', 'Cached Popular')],
          upcomingMovies: const [],
        ),
        cachedAt: DateTime.utc(2026, 7, 20),
      ),
      remote: const Left(NetworkFailure(message: 'No connection')),
    );
    final cubit = HomeCubit(repository);
    addTearDown(cubit.close);

    await cubit.loadMovies();

    expect(cubit.state.status, HomeStatus.loaded);
    expect(cubit.state.popularMovies.single.title, 'Cached Popular');
    expect(cubit.state.isFromCache, isTrue);
    expect(cubit.state.isRefreshing, isFalse);
    expect(cubit.state.failure?.message, 'No connection');
  });

  test('uses failure state when neither cache nor network is available', () async {
    final cubit = HomeCubit(
      _FakeHomeRepository(
        remote: const Left(NetworkFailure(message: 'No connection')),
      ),
    );
    addTearDown(cubit.close);

    await cubit.loadMovies();

    expect(cubit.state.status, HomeStatus.failure);
    expect(cubit.state.popularMovies, isEmpty);
    expect(cubit.state.isFromCache, isFalse);
  });
}

class _FakeHomeRepository extends HomeRepository {
  _FakeHomeRepository({this.cached, required this.remote}) : super(Dio());

  final CachedHomeFeed? cached;
  final Either<Failure, HomeFeedData> remote;

  @override
  CachedHomeFeed? readCachedHomeMovies() => cached;

  @override
  Future<Either<Failure, HomeFeedData>> fetchHomeMovies() async => remote;
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
