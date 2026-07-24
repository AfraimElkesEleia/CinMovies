import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/home/data/model/home_movie_model.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/movie_image.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/movie_rating.dart';
import 'package:flutter/material.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie, this.onTap, this.heroTag});

  final HomeMovieModel movie;
  final VoidCallback? onTap;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 148,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 0.72,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: heroTag ?? 'movie-card-${movie.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: MovieImage(path: movie.imageAsset),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.transparent,
                        AppColors.black.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          MovieRating(rating: movie.rating),
                          const Spacer(),
                          Text(
                            movie.year,
                            style: const TextStyle(
                              color: AppColors.iconMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
