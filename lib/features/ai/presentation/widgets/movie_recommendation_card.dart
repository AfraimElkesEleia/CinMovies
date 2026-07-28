import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/ai/domain/entities/movie_chat_models.dart';
import 'package:cinmovies_app/features/movies/presentation/widgets/movie_artwork.dart';
import 'package:flutter/material.dart';

class MovieRecommendationCard extends StatelessWidget {
  const MovieRecommendationCard({
    super.key,
    required this.recommendation,
    required this.heroTag,
    required this.onPressed,
  });

  final MovieRecommendation recommendation;
  final String heroTag;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final movie = recommendation.movie;
    return Semantics(
      button: true,
      label: 'Open details for ${movie.title}',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: MediaQuery.sizeOf(context).width.clamp(0, 430) * 0.72,
          constraints: const BoxConstraints(minWidth: 248, maxWidth: 306),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF151B2E),
            border: Border.all(color: AppColors.surfaceBorder),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Hero(
                tag: heroTag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 66,
                    height: 102,
                    child: MovieArtwork(source: movie.imageAsset),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        movie.year,
                        if (movie.duration.isNotEmpty) movie.duration,
                      ].where((value) => value.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.iconMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.ratingAmber,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          movie.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppColors.ratingAmber,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (movie.genres.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              movie.genres.first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.iconMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      recommendation.reason,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
