import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/features/browse/data/browse_genre.dart';
import 'package:cinmovies_app/features/browse/data/browse_repository.dart';
import 'package:cinmovies_app/features/browse/presentation/cubit/browse_cubit.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loadInitial loads genres and first movie page', () async {
    final repository = _FakeBrowseRepository(
      genresResult: const Right([
        BrowseGenre.all,
        BrowseGenre(id: 28, name: 'Action'),
      ]),
      pages: {
        'All:1': BrowseMoviesPage(
          movies: [_movie('1', 'Movie One')],
          page: 1,
          totalPages: 2,
        ),
      },
    );
    final cubit = BrowseCubit(repository);
    addTearDown(cubit.close);

    await cubit.loadInitial();

    expect(cubit.state.status, BrowseStatus.loaded);
    expect(cubit.state.genres.length, 2);
    expect(cubit.state.movies.single.title, 'Movie One');
    expect(cubit.state.currentPage, 1);
    expect(cubit.state.totalPages, 2);
  });

  test('loadInitial emits failure with no fake movies when first page fails', () async {
    final repository = _FakeBrowseRepository(
      genresResult: const Left(NetworkFailure(message: 'No connection')),
      failureKeys: {'All:1'},
    );
    final cubit = BrowseCubit(repository);
    addTearDown(cubit.close);

    await cubit.loadInitial();

    expect(cubit.state.status, BrowseStatus.failure);
    expect(cubit.state.movies, isEmpty);
    expect(cubit.state.failure?.message, 'No connection');
  });

  test('selectGenre resets movies and loads page one for selected genre', () async {
    const action = BrowseGenre(id: 28, name: 'Action');
    final repository = _FakeBrowseRepository(
      pages: {
        'All:1': BrowseMoviesPage(
          movies: [_movie('1', 'All Movie')],
          page: 1,
          totalPages: 1,
        ),
        'Action:1': BrowseMoviesPage(
          movies: [_movie('2', 'Action Movie')],
          page: 1,
          totalPages: 3,
        ),
      },
    );
    final cubit = BrowseCubit(repository);
    addTearDown(cubit.close);

    await cubit.loadInitial();
    await cubit.selectGenre(action);

    expect(cubit.state.selectedGenre, action);
    expect(cubit.state.movies.single.title, 'Action Movie');
    expect(cubit.state.currentPage, 1);
    expect(cubit.state.totalPages, 3);
  });

  test('loadNextPage appends movies and stops at totalPages', () async {
    final repository = _FakeBrowseRepository(
      pages: {
        'All:1': BrowseMoviesPage(
          movies: [_movie('1', 'Page One')],
          page: 1,
          totalPages: 2,
        ),
        'All:2': BrowseMoviesPage(
          movies: [_movie('2', 'Page Two')],
          page: 2,
          totalPages: 2,
        ),
      },
    );
    final cubit = BrowseCubit(repository);
    addTearDown(cubit.close);

    await cubit.loadInitial();
    await cubit.loadNextPage();
    await cubit.loadNextPage();

    expect(cubit.state.movies.map((movie) => movie.title), [
      'Page One',
      'Page Two',
    ]);
    expect(repository.movieRequests, ['All:1', 'All:2']);
  });

  test('refresh reloads page one for the active genre', () async {
    const action = BrowseGenre(id: 28, name: 'Action');
    final repository = _FakeBrowseRepository(
      pages: {
        'All:1': BrowseMoviesPage(
          movies: [_movie('1', 'All Movie')],
          page: 1,
          totalPages: 1,
        ),
        'Action:1': BrowseMoviesPage(
          movies: [_movie('2', 'Action Movie')],
          page: 1,
          totalPages: 2,
        ),
      },
    );
    final cubit = BrowseCubit(repository);
    addTearDown(cubit.close);

    await cubit.loadInitial();
    await cubit.selectGenre(action);
    repository.pages['Action:1'] = BrowseMoviesPage(
      movies: [_movie('3', 'Refreshed Action Movie')],
      page: 1,
      totalPages: 3,
    );

    await cubit.refresh();

    expect(cubit.state.selectedGenre, action);
    expect(cubit.state.movies.single.title, 'Refreshed Action Movie');
    expect(cubit.state.currentPage, 1);
    expect(cubit.state.totalPages, 3);
    expect(repository.movieRequests, ['All:1', 'Action:1', 'Action:1']);
  });
}

class _FakeBrowseRepository extends BrowseRepository {
  _FakeBrowseRepository({
    this.genresResult = const Right([BrowseGenre.all]),
    this.pages = const {},
    this.failureKeys = const {},
  }) : super(Dio());

  final Either<Failure, List<BrowseGenre>> genresResult;
  final Map<String, BrowseMoviesPage> pages;
  final Set<String> failureKeys;
  final List<String> movieRequests = [];

  @override
  Future<Either<Failure, List<BrowseGenre>>> fetchGenres() async {
    return genresResult;
  }

  @override
  Future<Either<Failure, BrowseMoviesPage>> fetchMovies({
    required int page,
    BrowseGenre genre = BrowseGenre.all,
  }) async {
    final key = '${genre.name}:$page';
    movieRequests.add(key);
    if (failureKeys.contains(key)) {
      return const Left(NetworkFailure(message: 'No connection'));
    }
    return Right(
      pages[key] ?? BrowseMoviesPage(movies: [_movie('$page', key)], page: page, totalPages: page),
    );
  }
}

Movie _movie(String id, String title) {
  return Movie(
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
    cast: const [],
    reviews: const [],
  );
}
