import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/core/widgets/app_shimmer.dart';
import 'package:cinmovies_app/features/browse/data/browse_genre.dart';
import 'package:cinmovies_app/features/browse/presentation/widgets/browse_search_bar.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/movie_card.dart';
import 'package:cinmovies_app/features/movie_details/data/model/movie_details_args.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:flutter/material.dart';

class BrowseHeader extends StatelessWidget {
  const BrowseHeader({
    super.key,
    required this.genres,
    required this.activeGenre,
    required this.movieCount,
    required this.onGenreSelected,
  });

  final List<BrowseGenre> genres;
  final BrowseGenre activeGenre;
  final int movieCount;
  final ValueChanged<BrowseGenre> onGenreSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Browse Movies',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        BrowseSearchBar(onTap: () => context.pushNamed(Routes.search)),
        const SizedBox(height: 16),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: genres.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final genre = genres[index];
              return _GenreChip(
                genre: genre,
                isActive: genre == activeGenre,
                onSelected: () => onGenreSelected(genre),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              '$movieCount movies',
              style: const TextStyle(
                color: AppColors.iconMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.sort_rounded,
              color: AppColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 6),
            const Text(
              'Popularity',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class BrowseMovieGrid extends StatelessWidget {
  const BrowseMovieGrid({super.key, required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid.builder(
        itemCount: movies.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (context, index) {
          final movie = movies[index];
          final heroTag = 'browse-card-$index-${movie.id}';
          return MovieCard(
            movie: movie,
            heroTag: heroTag,
            onTap: () {
              context.pushNamed(
                Routes.movieDetails,
                arguments: MovieDetailsArgs(movie: movie, heroTag: heroTag),
              );
            },
          );
        },
      ),
    );
  }
}

class BottomLoader extends StatelessWidget {
  const BottomLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: AppShimmer(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppShimmerBox(width: 70, height: 10, radius: 5),
            SizedBox(width: 8),
            AppShimmerBox(width: 34, height: 10, radius: 5),
          ],
        ),
      ),
    );
  }
}

class BrowseEmptyState extends StatelessWidget {
  const BrowseEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_filter_outlined,
            color: AppColors.textMuted,
            size: 38,
          ),
          SizedBox(height: 12),
          Text(
            'No movies found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class BrowseErrorBanner extends StatelessWidget {
  const BrowseErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.loginPrimary.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.loginPrimary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.genre,
    required this.isActive,
    required this.onSelected,
  });

  final BrowseGenre genre;
  final bool isActive;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(genre.name),
      selected: isActive,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: AppColors.loginPrimary,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: isActive ? AppColors.loginPrimary : AppColors.surfaceBorder,
      ),
      labelStyle: TextStyle(
        color: isActive ? AppColors.white : AppColors.textMuted,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}
