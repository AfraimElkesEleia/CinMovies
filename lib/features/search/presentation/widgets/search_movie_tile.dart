import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/movie_rating.dart';
import 'package:flutter/material.dart';

class SearchMovieTile extends StatelessWidget {
  const SearchMovieTile({super.key, required this.movie});

  final HomeMovieModel movie;

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
            child: Image.asset(
              movie.imageAsset,
              width: 62,
              height: 84,
              fit: BoxFit.cover,
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
                MovieRating(rating: movie.rating),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.iconMuted),
        ],
      ),
    );
  }
}
