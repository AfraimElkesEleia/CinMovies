import 'package:cinmovies_app/features/home/data/home_repository.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';

class MovieSectionArgs {
  MovieSectionArgs({required HomeMovieSection section})
    : title = section.title,
      homeSection = section,
      libraryListType = null,
      genreIds = const [];

  MovieSectionArgs.forYou({required List<int> genreIds})
    : title = HomeMovieSection.forYou.title,
      homeSection = HomeMovieSection.forYou,
      libraryListType = null,
      genreIds = List.unmodifiable(genreIds);

  const MovieSectionArgs.library({
    required this.title,
    required UserMovieListType type,
  }) : homeSection = null,
       libraryListType = type,
       genreIds = const [];

  final String title;
  final HomeMovieSection? homeSection;
  final UserMovieListType? libraryListType;
  final List<int> genreIds;

  bool get isLibrarySection => libraryListType != null;
}
