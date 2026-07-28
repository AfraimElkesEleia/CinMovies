import 'package:cinmovies_app/features/home/presentation/widgets/home_screen_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('search button invokes its callback', (tester) async {
    var searchPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeTopBar(
            onSearchPressed: () => searchPressed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Search movies'));

    expect(searchPressed, isTrue);
    expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
  });

  testWidgets('saved-data banner displays its message and retries', (
    tester,
  ) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeErrorBanner(
            message: 'Showing saved movies.',
            onRetry: () => retryCount++,
          ),
        ),
      ),
    );

    expect(find.text('Showing saved movies.'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

    await tester.tap(find.text('Retry'));

    expect(retryCount, 1);
  });
}
