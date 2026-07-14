import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';

class SearchMovieFilter {
  const SearchMovieFilter._();

  static List<HomeMovieModel> byQuery({
    required List<HomeMovieModel> movies,
    required String query,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return const [];

    return movies.where((movie) {
      final titleMatch = movie.title.toLowerCase().contains(normalizedQuery);
      final genreMatch = movie.genres.any(
        (genre) => genre.toLowerCase().contains(normalizedQuery),
      );
      final yearMatch = movie.year.contains(normalizedQuery);

      return titleMatch || genreMatch || yearMatch;
    }).toList();
  }
}
