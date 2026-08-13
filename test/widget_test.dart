import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/local/local_preferences_service.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/widgets/app_splash_overlay.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cinmovies_app/main.dart';

void main() {
  setUp(() async {
    await serviceLocator.reset();
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    serviceLocator.registerSingleton<LocalPreferencesService>(
      LocalPreferencesService(preferences),
    );
    serviceLocator.registerSingleton<AuthRepository>(_FakeAuthRepository());
  });

  testWidgets('App starts on onboarding route', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const CinMoviesApp(initialRoute: AppRoutes.onboarding),
    );

    expect(find.byKey(AppSplashOverlay.visualKey), findsOneWidget);

    await tester.pump();

    expect(find.text('Discover Movies\nYou\'ll Love'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2201));

    expect(find.byKey(AppSplashOverlay.visualKey), findsNothing);
    expect(find.text('Discover Movies\nYou\'ll Love'), findsOneWidget);
  });
}

class _FakeAuthRepository extends Fake implements AuthRepository {
  @override
  bool get isAuthenticated => false;

  @override
  bool get isGuest => false;
}
