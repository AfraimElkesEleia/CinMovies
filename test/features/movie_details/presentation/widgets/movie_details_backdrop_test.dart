import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_backdrop.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('share button provides its screen origin', (tester) async {
    Rect? shareOrigin;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MovieDetailsBackdrop(
            movie: _movie(),
            heroTag: 'movie-backdrop',
            isFavorite: false,
            isFavoriteLoading: false,
            onBackPressed: () {},
            onFavoritePressed: () {},
            onSharePressed: (origin) => shareOrigin = origin,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.ios_share_rounded));

    expect(shareOrigin, isNotNull);
    expect(shareOrigin!.width, greaterThan(0));
    expect(shareOrigin!.height, greaterThan(0));
  });
}

Movie _movie() {
  return const Movie(
    id: '693134',
    title: 'Dune: Part Two',
    imageAsset: 'assets/images/movie_ex1.jpg',
    genres: ['Science Fiction'],
    rating: 8.3,
    year: '2024',
    duration: '2h 46m',
    ageRating: 'PG-13',
    synopsis: 'Paul Atreides unites with Chani and the Fremen.',
    director: 'Denis Villeneuve',
    votes: '6.8K',
    cast: [],
    reviews: [],
  );
}
