import 'package:cinmovies_app/features/home/data/tmdb_movie_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TmdbMovieMapper', () {
    test('maps TMDB movie JSON into a home movie model', () {
      final movie = TmdbMovieMapper.fromJson({
        'id': 550,
        'title': 'Fight Club',
        'poster_path': '/poster.jpg',
        'release_date': '1999-10-15',
        'vote_average': 8.4,
        'vote_count': 12345,
        'overview': 'An insomniac office worker meets a soap maker.',
      });

      expect(movie.id, '550');
      expect(movie.title, 'Fight Club');
      expect(movie.imageAsset, 'https://image.tmdb.org/t/p/w500/poster.jpg');
      expect(movie.year, '1999');
      expect(movie.rating, 8.4);
      expect(movie.votes, '12.3K');
      expect(movie.synopsis, 'An insomniac office worker meets a soap maker.');
    });

    test('uses safe defaults when optional TMDB fields are missing', () {
      final movie = TmdbMovieMapper.fromJson({
        'id': 1,
        'original_title': 'Original Title',
      });

      expect(movie.id, '1');
      expect(movie.title, 'Original Title');
      expect(movie.imageAsset, 'assets/images/movie_ex1.jpg');
      expect(movie.year, 'N/A');
      expect(movie.rating, 0);
      expect(movie.votes, '0');
      expect(movie.synopsis, 'No synopsis available.');
    });

    test('maps a TMDB list response and skips entries without ids', () {
      final movies = TmdbMovieMapper.listFromResponse({
        'results': [
          {'id': 1, 'title': 'Movie One'},
          {'title': 'No ID'},
          {'id': 2, 'title': 'Movie Two'},
        ],
      });

      expect(movies.map((movie) => movie.id), ['1', '2']);
    });
  });
}
