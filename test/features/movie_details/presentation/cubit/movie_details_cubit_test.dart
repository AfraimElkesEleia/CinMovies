import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';
import 'package:cinmovies_app/features/movie_details/data/movie_details_repository.dart';
import 'package:cinmovies_app/features/movie_details/presentation/cubit/movie_details_cubit.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('load success emits full movie details and saved state', () async {
    final seed = _movie('1', 'Seed');
    final full = _movie('1', 'Full');
    final cubit = MovieDetailsCubit(
      _FakeDetailsRepository(
        Right(
          MovieDetailsResult(
            movie: full,
            similarMovies: [_movie('2', 'Similar')],
          ),
        ),
      ),
      _FakeLibraryRepository(
        containsResults: {
          UserMovieListType.favorite: true,
          UserMovieListType.watchlist: true,
        },
      ),
      seed,
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.status, MovieDetailsStatus.loaded);
    expect(cubit.state.movie.title, 'Full');
    expect(cubit.state.similarMovies.single.title, 'Similar');
    expect(cubit.state.isFavorite, isTrue);
    expect(cubit.state.inWatchlist, isTrue);
  });

  test('load falls back to seed movie when TMDB details fail', () async {
    final seed = _movie('1', 'Seed');
    final cubit = MovieDetailsCubit(
      _FakeDetailsRepository(const Left(NetworkFailure(message: 'No connection'))),
      _FakeLibraryRepository(),
      seed,
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.status, MovieDetailsStatus.failure);
    expect(cubit.state.movie.title, 'Seed');
    expect(cubit.state.failure?.message, 'No connection');
  });
}

class _FakeDetailsRepository extends MovieDetailsRepository {
  _FakeDetailsRepository(this.result) : super(Dio());

  final Either<Failure, MovieDetailsResult> result;

  @override
  Future<Either<Failure, MovieDetailsResult>> fetchMovieDetails(
    Movie seed,
  ) async {
    return result;
  }
}

class _FakeLibraryRepository implements LibraryRepository {
  _FakeLibraryRepository({this.containsResults = const {}});

  final Map<UserMovieListType, bool> containsResults;

  @override
  Future<Either<Failure, bool>> contains(
    Movie movie,
    UserMovieListType type,
  ) async {
    return Right(containsResults[type] ?? false);
  }

  @override
  Future<Either<Failure, int>> count(UserMovieListType type) async {
    return const Right(0);
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> movieRows(
    UserMovieListType type,
  ) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<Movie>>> movies(UserMovieListType type) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, void>> setListed(
    Movie movie,
    UserMovieListType type, {
    required bool listed,
  }) async {
    return const Right(null);
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
    availability: MovieAvailability.streaming,
    cast: const [],
    reviews: const [],
  );
}
