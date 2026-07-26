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
    required this.onLoadMore,
    required this.isLoadingMore,
    required this.hasMore,
  });

  final List<LibraryMovieModel> movies;
  final String emptyLabel;
  final ValueChanged<LibraryMovieModel> onRemovePressed;
  final void Function(LibraryMovieModel movie, String heroTag) onMoviePressed;
  final VoidCallback onLoadMore;
  final bool isLoadingMore;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                emptyLabel,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        if (hasMore &&
            !isLoadingMore &&
            metrics.pixels >= metrics.maxScrollExtent - 240) {
          onLoadMore();
        }
        return false;
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        itemCount: movies.length + (isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= movies.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.loginPrimary,
                ),
              ),
            );
          }

          final movie = movies[index];
          final heroTag = 'library-${movie.movieId}-$index';
          return LibraryMovieCard(
            movie: movie,
            heroTag: heroTag,
            onPressed: () => onMoviePressed(movie, heroTag),
            onRemovePressed: () => onRemovePressed(movie),
          );
        },
      ),
    );
  }
}
