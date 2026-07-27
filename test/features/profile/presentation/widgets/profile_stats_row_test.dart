import 'package:cinmovies_app/features/profile/presentation/widgets/profile_stats_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows favorites instead of watched movies', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProfileStatsRow(
            favoriteCount: 7,
            watchlistCount: 3,
            reviewCount: 2,
          ),
        ),
      ),
    );

    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Watched'), findsNothing);
    expect(find.text('7'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
  });
}
