import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';

class MovieDetailsArgs {
  const MovieDetailsArgs({required this.movie, required this.heroTag});

  final Movie movie;
  final String heroTag;
}
