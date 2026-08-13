import 'package:cinmovies_app/core/error/app_error.dart';
import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/features/home/data/home_repository.dart';
import 'package:cinmovies_app/features/home/presentation/model/movie_section_args.dart';
import 'package:cinmovies_app/features/home/presentation/cubit/movie_section_cubit.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/movies/presentation/model/movie_list_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loadInitial loads the first section page', () async {
    final repository = _FakeHomeRepository({
      'popular:1': MovieSectionPage(
        movies: [_movie('1', 'Alpha')],
        page: 1,
        totalPages: 2,
      ),
    });
    final cubit = MovieSectionCubit(
      repository,
      MovieSectionArgs(section: HomeMovieSection.popular),
    );
    addTearDown(cubit.close);

    await cubit.loadInitial();

    expect(cubit.state.status, MovieListStatus.loaded);
    expect(cubit.state.movies.single.title, 'Alpha');
    expect(cubit.state.currentPage, 1);
    expect(cubit.state.totalPages, 2);
  });

  test('loadNextPage appends movies', () async {
    final repository = _FakeHomeRepository({
      'popular:1': MovieSectionPage(
        movies: [_movie('1', 'Page One')],
        page: 1,
        totalPages: 2,
      ),
      'popular:2': MovieSectionPage(
        movies: [_movie('2', 'Page Two')],
        page: 2,
        totalPages: 2,
      ),
    });
    final cubit = MovieSectionCubit(
      repository,
      MovieSectionArgs(section: HomeMovieSection.popular),
    );
    addTearDown(cubit.close);

    await cubit.loadInitial();
    await cubit.loadNextPage();
    await cubit.loadNextPage();

    expect(cubit.state.movies.map((movie) => movie.title), [
      'Page One',
      'Page Two',
    ]);
    expect(repository.requests, ['popular:1', 'popular:2']);
  });

  test('For You pagination preserves the normalized genre IDs', () async {
    final repository = _FakeHomeRepository({
      'forYou:1': MovieSectionPage(
        movies: [_movie('1', 'Page One')],
        page: 1,
        totalPages: 2,
      ),
      'forYou:2': MovieSectionPage(
        movies: [_movie('2', 'Page Two')],
        page: 2,
        totalPages: 2,
      ),
    });
    final cubit = MovieSectionCubit(
      repository,
      MovieSectionArgs.forYou(genreIds: const [28, 878]),
    );
    addTearDown(cubit.close);

    await cubit.loadInitial();
    await cubit.loadNextPage();

    expect(repository.requests, ['forYou:1', 'forYou:2']);
    expect(repository.genreRequests, [
      [28, 878],
      [28, 878],
    ]);
  });

  test('query filters loaded movies locally', () async {
    final repository = _FakeHomeRepository({
      'upcoming:1': MovieSectionPage(
        movies: [_movie('1', 'Avatar'), _movie('2', 'Batman')],
        page: 1,
        totalPages: 1,
      ),
    });
    final cubit = MovieSectionCubit(
      repository,
      MovieSectionArgs(section: HomeMovieSection.upcoming),
    );
    addTearDown(cubit.close);

    await cubit.loadInitial();
    cubit.setQuery('ava');

    expect(cubit.state.visibleMovies.single.title, 'Avatar');
  });

  test('sort modes order visible movies', () async {
    final repository = _FakeHomeRepository({
      'popular:1': MovieSectionPage(
        movies: [
          _movie('1', 'Zulu', rating: 6, year: '2020'),
          _movie('2', 'Alpha', rating: 8, year: '2018'),
          _movie('3', 'Middle', rating: 7, year: '2024'),
        ],
        page: 1,
        totalPages: 1,
      ),
    });
    final cubit = MovieSectionCubit(
      repository,
      MovieSectionArgs(section: HomeMovieSection.popular),
    );
    addTearDown(cubit.close);

    await cubit.loadInitial();

    expect(cubit.state.visibleMovies.map((movie) => movie.title), [
      'Alpha',
      'Middle',
      'Zulu',
    ]);

    cubit.selectSortOption(MovieSortOption.title);
    expect(cubit.state.visibleMovies.map((movie) => movie.title), [
      'Alpha',
      'Middle',
      'Zulu',
    ]);

    cubit.selectSortOption(MovieSortOption.newest);
    expect(cubit.state.visibleMovies.map((movie) => movie.title), [
      'Middle',
      'Zulu',
      'Alpha',
    ]);
  });

  test('failure emits failure state without fake data', () async {
    final repository = _FakeHomeRepository(const {}, failures: {'popular:1'});
    final cubit = MovieSectionCubit(
      repository,
      MovieSectionArgs(section: HomeMovieSection.popular),
    );
    addTearDown(cubit.close);

    await cubit.loadInitial();

    expect(cubit.state.status, MovieListStatus.failure);
    expect(cubit.state.movies, isEmpty);
    expect(cubit.state.failure?.message, 'No connection');
  });
}

class _FakeHomeRepository extends Fake implements HomeRepository {
  _FakeHomeRepository(this.pages, {this.failures = const {}});

  final Map<String, MovieSectionPage> pages;
  final Set<String> failures;
  final List<String> requests = [];
  final List<List<int>> genreRequests = [];

  @override
  Future<Result<MovieSectionPage>> fetchMovieSection({
    required HomeMovieSection section,
    required int page,
    List<int> genreIds = const [],
  }) async {
    final key = '${section.name}:$page';
    requests.add(key);
    genreRequests.add([...genreIds]);
    if (failures.contains(key)) {
      return const Failure(NetworkAppError(message: 'No connection'));
    }
    return Success(
      pages[key] ??
          MovieSectionPage(
            movies: [_movie('$page', key)],
            page: page,
            totalPages: page,
          ),
    );
  }
}

Movie _movie(
  String id,
  String title, {
  double rating = 7,
  String year = '2026',
}) {
  return Movie(
    id: id,
    title: title,
    imageAsset: 'assets/images/movie_ex1.jpg',
    genres: const [],
    rating: rating,
    year: year,
    duration: 'N/A',
    ageRating: 'NR',
    synopsis: 'Synopsis',
    director: 'Unknown',
    votes: '1K',
    cast: const [],
    reviews: const [],
  );
}
