import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/error/default_error_mapper.dart';
import 'package:cinmovies_app/core/local/local_preferences_service.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/supabase/supabase_database_service.dart';
import 'package:cinmovies_app/core/supabase/supabase_storage_service.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:cinmovies_app/features/auth/presentation/widgets/guest_account_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late LocalPreferencesService preferences;

  setUp(() async {
    await serviceLocator.reset();
    SharedPreferences.setMockInitialValues({'is_guest_mode': true});
    preferences = LocalPreferencesService(
      await SharedPreferences.getInstance(),
    );
    final client = SupabaseClient(
      'https://localhost.invalid',
      'test-publishable-key',
    );
    serviceLocator.registerSingleton<AuthRepository>(
      SupabaseAuthRepository(
        SupabaseDatabaseService(client),
        SupabaseStorageService(client),
        preferences,
        const DefaultErrorMapper(),
      ),
    );
  });

  tearDown(() => serviceLocator.reset());

  testWidgets('locked guest action explains the restriction', (tester) async {
    await tester.pumpWidget(_testApp());

    await tester.tap(find.text('Open prompt'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to save favorite movies'), findsOne);
    expect(find.text('Sign in'), findsOne);
    expect(find.text('Create account'), findsOne);
  });

  testWidgets('sign in exits guest mode before navigating', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.tap(find.text('Open prompt'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Login destination'), findsOne);
    expect(preferences.isGuestMode, isFalse);
  });

  testWidgets('create account exits guest mode before navigating', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.tap(find.text('Open prompt'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Signup destination'), findsOne);
    expect(preferences.isGuestMode, isFalse);
  });
}

Widget _testApp() {
  return MaterialApp(
    routes: {
      AppRoutes.login: (_) =>
          const Scaffold(body: Center(child: Text('Login destination'))),
      AppRoutes.register: (_) =>
          const Scaffold(body: Center(child: Text('Signup destination'))),
    },
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showGuestAccountPrompt(
              context,
              feature: 'save favorite movies',
            ),
            child: const Text('Open prompt'),
          ),
        ),
      ),
    ),
  );
}
