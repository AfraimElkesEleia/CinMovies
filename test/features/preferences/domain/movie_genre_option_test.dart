import 'package:cinmovies_app/features/preferences/domain/movie_genre_option.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes supported favorite genre names to stable TMDB IDs', () {
    final ids = normalizeFavoriteGenreIds([
      ' Action ',
      'SCI-FI',
      'science fiction',
      'Sci Fi',
      'Comedy',
      'Unknown',
    ]);

    expect(ids, [28, 35, 878]);
  });

  test('every selectable genre has a unique TMDB ID', () {
    expect(movieGenreOptions.map((option) => option.tmdbId).toSet(), hasLength(12));
    expect(
      normalizeFavoriteGenreIds(
        movieGenreOptions.map((option) => option.genre),
      ),
      [12, 14, 16, 18, 27, 28, 35, 53, 80, 99, 878, 10749],
    );
  });

  test('maps TMDB Science Fiction back to the app display label', () {
    expect(movieGenreNameFromTmdbId(878), 'Sci-Fi');
    expect(movieGenreNameFromTmdbId(-1), isNull);
  });
}
