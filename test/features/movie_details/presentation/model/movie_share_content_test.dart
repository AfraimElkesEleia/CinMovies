import 'package:cinmovies_app/features/movie_details/presentation/model/movie_share_content.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds movie details and TMDB URL for sharing', () {
    final content = MovieShareContent.fromMovie(_movie());

    expect(content.title, 'Share Dune: Part Two');
    expect(content.subject, 'Check out Dune: Part Two');
    expect(
      content.text,
      'Check out Dune: Part Two (2024) on CinMovies\n'
      'Rating: 8.3/10\n'
      'https://www.themoviedb.org/movie/693134',
    );
  });

  test('omits an unavailable year from the shared title', () {
    final content = MovieShareContent.fromMovie(_movie(year: 'N/A'));

    expect(content.text, startsWith('Check out Dune: Part Two on CinMovies\n'));
  });
}

Movie _movie({String year = '2024'}) {
  return Movie(
    id: '693134',
    title: 'Dune: Part Two',
    imageAsset: 'assets/images/movie_ex1.jpg',
    genres: const ['Science Fiction'],
    rating: 8.3,
    year: year,
    duration: '2h 46m',
    ageRating: 'PG-13',
    synopsis: 'Paul Atreides unites with Chani and the Fremen.',
    director: 'Denis Villeneuve',
    votes: '6.8K',
    cast: const [],
    reviews: const [],
  );
}
