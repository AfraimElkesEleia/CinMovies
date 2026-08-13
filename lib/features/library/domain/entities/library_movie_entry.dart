import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:equatable/equatable.dart';

final class LibraryMovieEntry extends Equatable {
  const LibraryMovieEntry({required this.storedMovieId, required this.movie});

  final String storedMovieId;
  final Movie movie;

  @override
  List<Object> get props => [storedMovieId, movie];
}
