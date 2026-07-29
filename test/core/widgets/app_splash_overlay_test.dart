import 'package:cinmovies_app/core/widgets/app_splash_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('removes the splash and completes exactly once', (tester) async {
    var completionCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: AppSplashOverlay(
          duration: const Duration(milliseconds: 200),
          onFinished: () => completionCount++,
          child: const Scaffold(body: Text('Destination')),
        ),
      ),
    );

    expect(find.byKey(AppSplashOverlay.visualKey), findsOneWidget);
    expect(find.text('Destination'), findsOneWidget);
    expect(completionCount, 0);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 201));

    expect(find.byKey(AppSplashOverlay.visualKey), findsNothing);
    expect(find.text('Destination'), findsOneWidget);
    expect(completionCount, 1);

    await tester.pump(const Duration(seconds: 1));

    expect(completionCount, 1);
  });

  testWidgets('uses the reduced-motion duration when animations are disabled', (
    tester,
  ) async {
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: AppSplashOverlay(
            duration: const Duration(seconds: 3),
            reducedMotionDuration: const Duration(milliseconds: 150),
            onFinished: () => completed = true,
            child: const Scaffold(body: Text('Destination')),
          ),
        ),
      ),
    );

    expect(find.byKey(AppSplashOverlay.visualKey), findsOneWidget);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 151));

    expect(find.byKey(AppSplashOverlay.visualKey), findsNothing);
    expect(completed, isTrue);
  });
}
