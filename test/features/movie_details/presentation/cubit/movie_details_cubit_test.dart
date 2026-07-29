import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';
import 'package:cinmovies_app/features/movie_details/data/movie_details_repository.dart';
import 'package:cinmovies_app/features/movie_details/presentation/cubit/movie_details_cubit.dart';
import 'package:cinmovies_app/features/reviews/data/model/community_review.dart';
import 'package:cinmovies_app/features/reviews/data/review_repository.dart';
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
          MovieDetailsData(
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
      _FakeReviewRepository(),
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
      _FakeDetailsRepository(
        const Left(Failure(message: 'No connection')),
      ),
      _FakeLibraryRepository(),
      _FakeReviewRepository(),
      seed,
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.status, MovieDetailsStatus.failure);
    expect(cubit.state.movie.title, 'Seed');
    expect(cubit.state.failure?.message, 'No connection');
  });

  test('load keeps cached rich details when refresh fails', () async {
    final seed = _movie('1', 'Seed');
    final cachedMovie = _movie('1', 'Cached Full');
    final cachedAt = DateTime.utc(2026, 7, 20);
    final cubit = MovieDetailsCubit(
      _FakeDetailsRepository(
        const Left(Failure(message: 'No connection')),
        cached: CachedMovieDetails(
          data: MovieDetailsData(
            movie: cachedMovie,
            similarMovies: [_movie('2', 'Cached Similar')],
            videoKey: 'saved-video',
          ),
          cachedAt: cachedAt,
        ),
      ),
      _FakeLibraryRepository(),
      _FakeReviewRepository(),
      seed,
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.status, MovieDetailsStatus.loaded);
    expect(cubit.state.movie.title, 'Cached Full');
    expect(cubit.state.similarMovies.single.title, 'Cached Similar');
    expect(cubit.state.videoKey, 'saved-video');
    expect(cubit.state.isFromCache, isTrue);
    expect(cubit.state.hasRichDetails, isTrue);
    expect(cubit.state.cachedAt, cachedAt);
    expect(cubit.state.failure?.message, 'No connection');
  });

  test('guest mode skips saved state and blocks account mutations', () async {
    final movie = _movie('1', 'Guest movie');
    final library = _FakeLibraryRepository();
    final reviews = _FakeReviewRepository();
    final cubit = MovieDetailsCubit(
      _FakeDetailsRepository(
        Right(MovieDetailsData(movie: movie, similarMovies: const [])),
      ),
      library,
      reviews,
      movie,
      isGuest: true,
    );
    addTearDown(cubit.close);

    await cubit.load();
    final review = CommunityReview(
      id: 'review-1',
      movie: movie,
      authorId: 'account-1',
      authorName: 'Reviewer',
      authorAvatarUrl: '',
      rating: 8,
      title: 'Title',
      body: 'Body',
      spoiler: false,
      createdAt: DateTime.utc(2026, 7, 29),
      likeCount: 0,
      dislikeCount: 0,
      currentUserReaction: null,
      isOwnReview: false,
    );

    expect(await cubit.toggleFavorite(), isFalse);
    expect(await cubit.toggleWatchlist(), isFalse);
    expect(
      await cubit.submitReview(
        rating: 8,
        body: 'Guest review',
        spoiler: false,
      ),
      isFalse,
    );
    expect(
      await cubit.toggleReviewReaction(review, ReviewReaction.like),
      isFalse,
    );
    expect(library.containsCalls, 0);
    expect(library.setListedCalls, 0);
    expect(reviews.upsertCalls, 0);
    expect(reviews.setReactionCalls, 0);
  });
}

class _FakeReviewRepository implements ReviewRepository {
  int upsertCalls = 0;
  int setReactionCalls = 0;

  @override
  Future<Either<Failure, int>> countForCurrentUser() async {
    return const Right(0);
  }

  @override
  Future<Either<Failure, void>> clearReaction(String reviewId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteReview(String reviewId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<CommunityReview>>> reviewsForCurrentUser() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<CommunityReview>>> reviewsForMovie(Movie movie) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, void>> setReaction({
    required String reviewId,
    required ReviewReaction reaction,
  }) async {
    setReactionCalls++;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> upsertReview({
    required Movie movie,
    required double rating,
    String? title,
    String? body,
    bool spoiler = false,
  }) async {
    upsertCalls++;
    return const Right(null);
  }
}

class _FakeDetailsRepository extends MovieDetailsRepository {
  _FakeDetailsRepository(this.result, {this.cached}) : super(Dio());

  final Either<Failure, MovieDetailsData> result;
  final CachedMovieDetails? cached;

  @override
  CachedMovieDetails? readCachedMovieDetails(Movie seed) => cached;

  @override
  Future<Either<Failure, MovieDetailsData>> fetchMovieDetails(
    Movie seed,
  ) async {
    return result;
  }
}

class _FakeLibraryRepository implements LibraryRepository {
  _FakeLibraryRepository({this.containsResults = const {}});

  final Map<UserMovieListType, bool> containsResults;
  int containsCalls = 0;
  int setListedCalls = 0;

  @override
  Future<Either<Failure, bool>> contains(
    Movie movie,
    UserMovieListType type,
  ) async {
    containsCalls++;
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
  Future<Either<Failure, List<Map<String, dynamic>>>> movieRowsPage({
    required UserMovieListType type,
    required int page,
    required int pageSize,
  }) async {
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
    setListedCalls++;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> removeMovieIdFromList({
    required String movieId,
    required UserMovieListType type,
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
    cast: const [],
    reviews: const [],
  );
}
