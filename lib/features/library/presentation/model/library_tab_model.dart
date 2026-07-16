import 'package:cinmovies_app/features/library/presentation/model/library_movie_model.dart';

class LibraryTabModel {
  const LibraryTabModel({
    required this.label,
    required this.emptyLabel,
    required this.movies,
  });

  final String label;
  final String emptyLabel;
  final List<LibraryMovieModel> movies;
}
