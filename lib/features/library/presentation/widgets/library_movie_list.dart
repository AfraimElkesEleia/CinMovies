import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/library/presentation/model/library_movie_model.dart';
import 'package:cinmovies_app/features/library/presentation/widgets/library_movie_card.dart';
import 'package:flutter/material.dart';

class LibraryMovieList extends StatelessWidget {
  const LibraryMovieList({
    super.key,
    required this.movies,
    required this.emptyLabel,
    required this.onRemovePressed,
    required this.onMoviePressed,
    this.showDownloadActions = false,
  });

  final List<LibraryMovieModel> movies;
  final String emptyLabel;
  final ValueChanged<LibraryMovieModel> onRemovePressed;
  final void Function(LibraryMovieModel movie, String heroTag) onMoviePressed;
  final bool showDownloadActions;

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      itemCount: movies.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final movie = movies[index];
        final heroTag = 'library-${movie.movieId}-$index';
        return LibraryMovieCard(
          movie: movie,
          heroTag: heroTag,
          showDownloadActions: showDownloadActions,
          onPressed: () => onMoviePressed(movie, heroTag),
          onRemovePressed: () => onRemovePressed(movie),
        );
      },
    );
  }
}
