import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_primitives.dart';
import 'package:flutter/material.dart';

class MovieDetailsInfo extends StatelessWidget {
  const MovieDetailsInfo({
    super.key,
    required this.movie,
    required this.inWatchlist,
    required this.onTrailerPressed,
    required this.onWatchlistPressed,
  });

  final HomeMovieModel movie;
  final bool inWatchlist;
  final VoidCallback onTrailerPressed;
  final VoidCallback onWatchlistPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final genre in movie.genres) DetailsGenreChip(label: genre),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            movie.title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DetailsMetaText(movie.year),
              const DetailsMetaDot(),
              DetailsMetaText(movie.duration),
              const DetailsMetaDot(),
              DetailsAgeRating(label: movie.ageRating),
            ],
          ),
          const SizedBox(height: 12),
          _MovieRatingSummary(movie: movie),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.loginPrimary,
                        AppColors.loginPrimaryDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: onTrailerPressed,
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text('Watch Trailer'),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shadowColor: AppColors.transparent,
                      backgroundColor: AppColors.transparent,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _WatchlistButton(
                inWatchlist: inWatchlist,
                onPressed: onWatchlistPressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MovieRatingSummary extends StatelessWidget {
  const _MovieRatingSummary({required this.movie});

  final HomeMovieModel movie;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: AppColors.ratingAmber, size: 18),
        const SizedBox(width: 4),
        Text(
          movie.rating.toStringAsFixed(1),
          style: const TextStyle(
            color: AppColors.ratingAmber,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Text(
          '/10',
          style: TextStyle(
            color: AppColors.iconMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '(${movie.votes} votes)',
          style: const TextStyle(
            color: AppColors.iconMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _WatchlistButton extends StatelessWidget {
  const _WatchlistButton({
    required this.inWatchlist,
    required this.onPressed,
  });

  final bool inWatchlist;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 52,
        decoration: BoxDecoration(
          color: inWatchlist
              ? AppColors.loginPrimary.withValues(alpha: 0.10)
              : AppColors.surface,
          border: Border.all(
            color: inWatchlist
                ? AppColors.loginPrimary
                : AppColors.surfaceBorder,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          inWatchlist ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: inWatchlist ? AppColors.loginPrimary : AppColors.textMuted,
        ),
      ),
    );
  }
}
