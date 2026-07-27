import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';

class MovieShareContent {
  const MovieShareContent({
    required this.title,
    required this.subject,
    required this.text,
  });

  factory MovieShareContent.fromMovie(Movie movie) {
    final movieTitle = movie.title.trim();
    final year = movie.year.trim();
    final displayTitle = year.isEmpty || year == 'N/A'
        ? movieTitle
        : '$movieTitle ($year)';
    final movieUrl = Uri.https(
      'www.themoviedb.org',
      '/movie/${movie.id.trim()}',
    );

    return MovieShareContent(
      title: 'Share $movieTitle',
      subject: 'Check out $movieTitle',
      text:
          'Check out $displayTitle on CinMovies\n'
          'Rating: ${movie.rating.toStringAsFixed(1)}/10\n'
          '$movieUrl',
    );
  }

  final String title;
  final String subject;
  final String text;
}
