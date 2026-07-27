import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/profile/data/profile_repository.dart';
import 'package:cinmovies_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:cinmovies_app/features/reviews/data/model/community_review.dart';
import 'package:cinmovies_app/features/reviews/data/review_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('loads favorite count from the Supabase-backed library repository', () async {
    final libraryRepository = _FakeLibraryRepository({
      UserMovieListType.favorite: 7,
      UserMovieListType.watchlist: 3,
    });
    final cubit = ProfileCubit(
      _FakeProfileRepository(),
      libraryRepository,
      _FakeAuthRepository(),
      _FakeReviewRepository(),
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.status, ProfileStatus.loaded);
    expect(cubit.state.favoriteCount, 7);
    expect(cubit.state.watchlistCount, 3);
    expect(cubit.state.reviewCount, 2);
    expect(libraryRepository.requestedTypes, [
      UserMovieListType.favorite,
      UserMovieListType.watchlist,
    ]);
    expect(
      libraryRepository.requestedTypes,
      isNot(contains(UserMovieListType.watched)),
    );
  });
}

class _FakeProfileRepository implements ProfileRepository {
  @override
  Future<Either<Failure, Map<String, dynamic>?>> currentProfile() async {
    return const Right({'full_name': 'Movie Fan'});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLibraryRepository implements LibraryRepository {
  _FakeLibraryRepository(this.counts);

  final Map<UserMovieListType, int> counts;
  final List<UserMovieListType> requestedTypes = [];

  @override
  Future<Either<Failure, int>> count(UserMovieListType type) async {
    requestedTypes.add(type);
    return Right(counts[type] ?? 0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthRepository implements AuthRepository {
  @override
  User? get currentUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeReviewRepository implements ReviewRepository {
  @override
  Future<Either<Failure, int>> countForCurrentUser() async {
    return const Right(2);
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
  Future<Either<Failure, List<CommunityReview>>> reviewsForMovie(
    Movie movie,
  ) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, void>> setReaction({
    required String reviewId,
    required ReviewReaction reaction,
  }) async {
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
    return const Right(null);
  }
}
