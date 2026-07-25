import 'package:cinmovies_app/features/library/presentation/model/library_movie_model.dart';

class LibraryTabModel {
  const LibraryTabModel({
    required this.label,
    required this.type,
    required this.emptyLabel,
    required this.movies,
    this.page = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final String label;
  final String type;
  final String emptyLabel;
  final List<LibraryMovieModel> movies;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  LibraryTabModel copyWith({
    List<LibraryMovieModel>? movies,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return LibraryTabModel(
      label: label,
      type: type,
      emptyLabel: emptyLabel,
      movies: movies ?? this.movies,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
