import 'package:cinmovies_app/features/library/presentation/widgets/trailer_history_list.dart';
import 'package:cinmovies_app/features/trailers/domain/entities/trailer_history_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows responsive progress bar and percentage', (tester) async {
    tester.view.physicalSize = const Size(340, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var tapped = false;
    var removed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrailerHistoryList(
            entries: [_entry()],
            emptyLabel: 'Empty',
            onPressed: (_) => tapped = true,
            onRemovePressed: (_) => removed = true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('35%'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == '35% watched' &&
            widget.properties.value == '35%',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Movie Trailer'));
    expect(tapped, isTrue);

    await tester.tap(find.byTooltip('Remove from history'));
    expect(removed, isTrue);
  });
}

TrailerHistoryEntry _entry() {
  return TrailerHistoryEntry(
    videoKey: 'video-key',
    movieId: '10',
    title: 'Movie Trailer',
    imageAsset: 'assets/images/movie_ex1.jpg',
    watchedSeconds: 35,
    totalSeconds: 100,
    updatedAt: DateTime.utc(2026),
  );
}
