import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';
import 'package:cinmovies_app/features/profile/data/profile_repository.dart';
import 'package:cinmovies_app/features/profile/domain/entities/user_profile.dart';
import 'package:cinmovies_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:cinmovies_app/features/reviews/data/review_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'loads favorite count from the Supabase-backed library repository',
    () async {
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
    },
  );
}

class _FakeProfileRepository implements ProfileRepository {
  @override
  Future<Result<UserProfile?>> currentProfile() async {
    return const Success(UserProfile(fullName: 'Movie Fan'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLibraryRepository implements LibraryRepository {
  _FakeLibraryRepository(this.counts);

  final Map<UserMovieListType, int> counts;
  final List<UserMovieListType> requestedTypes = [];

  @override
  Future<Result<int>> count(UserMovieListType type) async {
    requestedTypes.add(type);
    return Success(counts[type] ?? 0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthRepository implements AuthRepository {
  @override
  String? get currentUserEmail => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeReviewRepository implements ReviewRepository {
  @override
  Future<Result<int>> countForCurrentUser() async {
    return const Success(2);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
