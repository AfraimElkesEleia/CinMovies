import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:flutter/material.dart';

class SimilarMoviesSection extends StatelessWidget {
  const SimilarMoviesSection({
    super.key,
    required this.movies,
    required this.onMoviePressed,
    this.onSeeAllPressed,
  });

  final List<HomeMovieModel> movies;
  final ValueChanged<HomeMovieModel> onMoviePressed;
  final VoidCallback? onSeeAllPressed;

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Similar Movies',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onSeeAllPressed,
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      color: AppColors.loginPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 180,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: movies.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final movie = movies[index];

                return GestureDetector(
                  onTap: () => onMoviePressed(movie),
                  child: _SimilarMoviePoster(movie: movie),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SimilarMoviePoster extends StatelessWidget {
  const _SimilarMoviePoster({required this.movie});

  final HomeMovieModel movie;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(movie.imageAsset, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.transparent,
                    AppColors.black.withValues(alpha: 0.86),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Text(
                movie.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
