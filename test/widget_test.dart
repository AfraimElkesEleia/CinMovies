import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/local/local_preferences_service.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cinmovies_app/main.dart';

void main() {
  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    sl.registerSingleton<LocalPreferencesService>(
      LocalPreferencesService(preferences),
    );
    sl.registerSingleton<AuthRepository>(_FakeAuthRepository());
  });

  testWidgets('App starts on onboarding route', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp(initialRoute: Routes.onBoarding));

    await tester.pump();

    expect(find.text('Discover Movies\nYou\'ll Love'), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  User? get currentUser => null;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<String> resolveInitialRoute() async => Routes.onBoarding;

  @override
  Future<Either<Failure, AuthResponse>> signIn({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, AuthResponse>> signUp({
    required String fullName,
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}
