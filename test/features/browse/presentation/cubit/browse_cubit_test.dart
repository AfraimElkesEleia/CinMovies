import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/features/browse/data/browse_genre.dart';
import 'package:cinmovies_app/features/browse/data/browse_repository.dart';
import 'package:cinmovies_app/features/browse/presentation/cubit/browse_cubit.dart';
import 'package:cinmovies_app/features/home/presentation/data/home_mock_data.dart';
import 'package:cinmovies_app/features/home/data/model/home_movie_model.dart';
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

  test('loadInitial falls back to mock movies when first movie load fails', () async {
    final repository = _FakeBrowseRepository(
      genresResult: const Left(NetworkFailure(message: 'No connection')),
      failureKeys: {'All:1'},
    );
    final cubit = BrowseCubit(repository);
    addTearDown(cubit.close);

    await cubit.loadInitial();

    expect(cubit.state.status, BrowseStatus.failure);
    expect(cubit.state.movies, kHomeMovies);
    expect(cubit.state.failure?.message, 'No connection');
  });

  test('setGenre resets movies and loads page one for selected genre', () async {
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
    await cubit.setGenre(action);

    expect(cubit.state.activeGenre, action);
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
