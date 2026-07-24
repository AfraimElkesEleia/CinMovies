import 'package:cinmovies_app/features/home/data/model/home_movie_model.dart';

class MovieDetailsArgs {
  const MovieDetailsArgs({required this.movie, required this.heroTag});

  final HomeMovieModel movie;
  final String heroTag;
}
