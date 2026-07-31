import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/local/local_preferences_service.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/supabase/supabase_database_service.dart';
import 'package:cinmovies_app/core/supabase/supabase_storage_service.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:cinmovies_app/features/login/presentation/login_screen.dart';
import 'package:cinmovies_app/features/preferences/data/genre_preferences_repository.dart';
import 'package:cinmovies_app/features/signup/presentation/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late LocalPreferencesService preferences;

  setUp(() async {
    await serviceLocator.reset();
    SharedPreferences.setMockInitialValues({});
    preferences = LocalPreferencesService(
      await SharedPreferences.getInstance(),
    );
    final client = SupabaseClient(
      'https://localhost.invalid',
      'test-publishable-key',
    );
    serviceLocator.registerSingleton<AuthRepository>(
      AuthRepository(
        SupabaseDatabaseService(client),
        SupabaseStorageService(client),
        preferences,
      ),
    );
    serviceLocator.registerSingleton<GenrePreferencesRepository>(
      _FakeGenrePreferencesRepository(),
    );
  });

  tearDown(() => serviceLocator.reset());

  testWidgets('login removes social options and continues as guest', (
    tester,
  ) async {
    await _setLargeTestSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.home: (_) =>
              const Scaffold(body: Center(child: Text('Home destination'))),
          AppRoutes.register: (_) => const SignupScreen(),
        },
        home: const LoginScreen(),
      ),
    );

    expect(find.text('Google'), findsNothing);
    expect(find.text('Facebook'), findsNothing);

    await tester.tap(find.text('Continue as Guest'));
    await tester.pumpAndSettle();

    expect(find.text('Home destination'), findsOne);
    expect(preferences.isGuestMode, isTrue);
  });

  testWidgets('signup removes social options', (tester) async {
    await _setLargeTestSurface(tester);
    await tester.pumpWidget(
      const MaterialApp(home: SignupScreen()),
    );
    await tester.pump();

    expect(find.text('Google'), findsNothing);
    expect(find.text('Facebook'), findsNothing);
    expect(find.text('or continue with'), findsNothing);
    expect(find.text('Create Account'), findsWidgets);
  });
}

Future<void> _setLargeTestSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _FakeGenrePreferencesRepository
    implements GenrePreferencesRepository {
  @override
  String? get userScopeId => null;

  @override
  Set<String> cachedFavoriteGenres() => {};

  @override
  Future<Set<String>> loadFavoriteGenres() async => {};

  @override
  Future<void> saveFavoriteGenres(Set<String> genreNames) async {}

  @override
  Future<void> syncCachedFavoriteGenres() async {}

  @override
  Stream<Set<String>> watchFavoriteGenres() => const Stream.empty();
}
