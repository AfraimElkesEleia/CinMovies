import 'package:cinmovies_app/core/error/default_error_mapper.dart';
import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/core/local/local_preferences_service.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/supabase/supabase_database_service.dart';
import 'package:cinmovies_app/core/supabase/supabase_storage_service.dart';
import 'package:cinmovies_app/features/app/presentation/cubit/app_bootstrap_cubit.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late LocalPreferencesService preferences;
  late AuthRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'has_passed_onboarding': true});
    preferences = LocalPreferencesService(
      await SharedPreferences.getInstance(),
    );
    final client = SupabaseClient(
      'https://localhost.invalid',
      'test-publishable-key',
    );
    repository = SupabaseAuthRepository(
      SupabaseDatabaseService(client),
      SupabaseStorageService(client),
      preferences,
      const DefaultErrorMapper(),
    );
  });

  test('continue as guest persists a local session without a user', () async {
    final result = await repository.continueAsGuest();

    expect(result.isSuccess, isTrue);
    expect(repository.isAuthenticated, isFalse);
    expect(preferences.isGuestMode, isTrue);
    expect(repository.isGuest, isTrue);
    final cubit = AppBootstrapCubit(repository, preferences);
    addTearDown(cubit.close);
    expect(await cubit.resolveInitialRoute(), AppRoutes.home);
  });

  test('leaving guest mode returns the next launch to login', () async {
    await repository.continueAsGuest();

    final result = await repository.leaveGuestMode();

    expect(result.isSuccess, isTrue);
    expect(preferences.isGuestMode, isFalse);
    expect(repository.isGuest, isFalse);
    final cubit = AppBootstrapCubit(repository, preferences);
    addTearDown(cubit.close);
    expect(await cubit.resolveInitialRoute(), AppRoutes.login);
  });

  test('bootstrap prioritizes onboarding over a saved guest session', () async {
    await preferences.setGuestMode(true);
    await preferences.setHasPassedOnboarding(false);
    final cubit = AppBootstrapCubit(repository, preferences);
    addTearDown(cubit.close);

    expect(await cubit.resolveInitialRoute(), AppRoutes.onboarding);
  });

  test('bootstrap restores a saved guest session after onboarding', () async {
    await preferences.setGuestMode(true);
    final cubit = AppBootstrapCubit(repository, preferences);
    addTearDown(cubit.close);

    expect(await cubit.resolveInitialRoute(), AppRoutes.home);
  });
}
