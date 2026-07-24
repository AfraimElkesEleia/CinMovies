import 'package:cinmovies_app/features/home/data/home_repository.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';

class MovieSectionArgs {
  MovieSectionArgs({required HomeMovieSection section})
    : title = section.title,
      homeSection = section,
      libraryListType = null;

  const MovieSectionArgs.library({
    required this.title,
    required UserMovieListType type,
  }) : homeSection = null,
       libraryListType = type;

  final String title;
  final HomeMovieSection? homeSection;
  final UserMovieListType? libraryListType;

  bool get isLibrarySection => libraryListType != null;
}
