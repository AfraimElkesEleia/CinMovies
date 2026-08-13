import 'package:cinmovies_app/core/error/default_error_mapper.dart';
import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/core/local/local_preferences_service.dart';
import 'package:cinmovies_app/core/supabase/supabase_database_service.dart';
import 'package:cinmovies_app/core/supabase/supabase_storage_service.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:cinmovies_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:cinmovies_app/features/preferences/data/genre_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

void main() {
  test('continue as guest emits guest loading and success states', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = LocalPreferencesService(
      await SharedPreferences.getInstance(),
    );
    final client = SupabaseClient(
      'https://localhost.invalid',
      'test-publishable-key',
    );
    final repository = SupabaseAuthRepository(
      SupabaseDatabaseService(client),
      SupabaseStorageService(client),
      preferences,
      const DefaultErrorMapper(),
    );
    final cubit = AuthCubit(repository, _FakeGenrePreferencesRepository());
    addTearDown(cubit.close);

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const AuthState(
          status: AuthSubmissionStatus.loading,
          operation: AuthSubmissionOperation.guest,
        ),
        const AuthState(
          status: AuthSubmissionStatus.success,
          operation: AuthSubmissionOperation.guest,
        ),
      ]),
    );

    await cubit.continueAsGuest();
    await expectation;

    expect(preferences.isGuestMode, isTrue);
    expect(
      cubit.state.isLoadingOperation(AuthSubmissionOperation.guest),
      isFalse,
    );
  });
}

class _FakeGenrePreferencesRepository implements GenrePreferencesRepository {
  @override
  String? get userScopeId => null;

  @override
  Set<String> cachedFavoriteGenres() => {};

  @override
  Future<Result<Set<String>>> loadFavoriteGenres() async => const Success({});

  @override
  Future<Result<void>> saveFavoriteGenres(Set<String> genreNames) async =>
      const Success(null);

  @override
  Future<Result<void>> syncCachedFavoriteGenres() async => const Success(null);

  @override
  Stream<Set<String>> watchFavoriteGenres() => const Stream.empty();
}
