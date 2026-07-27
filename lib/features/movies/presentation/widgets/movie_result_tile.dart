import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/movies/presentation/widgets/movie_artwork.dart';
import 'package:cinmovies_app/features/movies/presentation/widgets/movie_rating_badge.dart';
import 'package:flutter/material.dart';

class MovieResultTile extends StatelessWidget {
  const MovieResultTile({
    super.key,
    required this.movie,
    required this.heroTag,
  });

  final Movie movie;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 62,
              height: 84,
              child: Hero(
                tag: heroTag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: MovieArtwork(source: movie.imageAsset),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${movie.year} - ${movie.genres.join(', ')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.iconMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                MovieRatingBadge(rating: movie.rating),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.iconMuted),
        ],
      ),
    );
  }
}
