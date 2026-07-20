import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/movie_card.dart';
import 'package:flutter/material.dart';

class ProfileMovieSection extends StatelessWidget {
  const ProfileMovieSection({
    super.key,
    required this.title,
    required this.movies,
    required this.onMoviePressed,
    this.onSeeAllPressed,
  });

  final String title;
  final List<HomeMovieModel> movies;
  final ValueChanged<HomeMovieModel> onMoviePressed;
  final VoidCallback? onSeeAllPressed;

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
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
        const SizedBox(height: 8),
        SizedBox(
          height: 206,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final movie = movies[index];

              return MovieCard(
                movie: movie,
                onTap: () => onMoviePressed(movie),
              );
            },
          ),
        ),
      ],
    );
  }
}
