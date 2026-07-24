import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/movie_image.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_primitives.dart';
import 'package:flutter/material.dart';

class MovieDetailsBackdrop extends StatelessWidget {
  const MovieDetailsBackdrop({
    super.key,
    required this.movie,
    required this.heroTag,
    required this.isFavorite,
    required this.isFavoriteLoading,
    required this.onBackPressed,
    required this.onFavoritePressed,
    required this.onSharePressed,
  });

  final Movie movie;
  final String heroTag;
  final bool isFavorite;
  final bool isFavoriteLoading;
  final VoidCallback onBackPressed;
  final VoidCallback onFavoritePressed;
  final VoidCallback onSharePressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: heroTag,
            child: ClipRRect(
              borderRadius: BorderRadius.zero,
              child: MovieImage(path: movie.imageAsset),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.scaffoldBackground.withValues(alpha: 0.28),
                  AppColors.scaffoldBackground.withValues(alpha: 0),
                  AppColors.scaffoldBackground.withValues(alpha: 0.96),
                ],
                stops: const [0, 0.42, 1],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 20,
            right: 20,
            child: Row(
              children: [
                DetailsGlassIconButton(
                  icon: Icons.chevron_left_rounded,
                  onPressed: onBackPressed,
                ),
                const Spacer(),
                DetailsGlassIconButton(
                  icon: Icons.ios_share_rounded,
                  onPressed: onSharePressed,
                  size: 18,
                ),
                const SizedBox(width: 8),
                DetailsGlassIconButton(
                  icon: isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? AppColors.loginPrimary : AppColors.white,
                  onPressed: onFavoritePressed,
                  isLoading: isFavoriteLoading,
                  size: 19,
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            bottom: 20,
            child: DetailsAvailabilityBadge(availability: movie.availability),
          ),
        ],
      ),
    );
  }
}
