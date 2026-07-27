import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/movies/presentation/model/movie_list_options.dart';
import 'package:cinmovies_app/features/movies/presentation/widgets/movie_result_tile.dart';
import 'package:cinmovies_app/features/movies/presentation/widgets/movie_results_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reports the selected movie and generated hero tag', (
    tester,
  ) async {
    Movie? selectedMovie;
    String? selectedHeroTag;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MovieResultsList(
            query: 'Dune',
            movies: const [_movie],
            status: MovieListStatus.loaded,
            sortOption: MovieSortOption.rating,
            onSortOptionChanged: (_) {},
            onMoviePressed: (movie, heroTag) {
              selectedMovie = movie;
              selectedHeroTag = heroTag;
            },
            heroTagPrefix: 'test-results',
          ),
        ),
      ),
    );

    await tester.tap(find.byType(MovieResultTile));

    expect(selectedMovie, same(_movie));
    expect(selectedHeroTag, 'test-results-0-1');
  });
}

const _movie = Movie(
  id: '1',
  title: 'Dune',
  imageAsset: 'assets/images/movie_ex1.jpg',
  genres: ['Science Fiction'],
  rating: 8.0,
  year: '2021',
  duration: '2h 35m',
  ageRating: 'PG-13',
  synopsis: 'A noble family becomes embroiled in a war for a desert planet.',
  director: 'Denis Villeneuve',
  votes: '1K',
  cast: [],
  reviews: [],
);
