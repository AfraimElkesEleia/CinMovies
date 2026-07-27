import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/core/widgets/app_shimmer.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/movies/presentation/model/movie_list_options.dart';
import 'package:cinmovies_app/features/movies/presentation/widgets/movie_result_tile.dart';
import 'package:cinmovies_app/features/movies/presentation/widgets/movie_results_empty_state.dart';
import 'package:flutter/material.dart';

typedef MovieResultPressed = void Function(Movie movie, String heroTag);

class MovieResultsList extends StatelessWidget {
  const MovieResultsList({
    super.key,
    required this.query,
    required this.movies,
    required this.status,
    required this.sortOption,
    required this.onSortOptionChanged,
    required this.onMoviePressed,
    this.isLoadingMore = false,
    this.failureMessage,
    this.controller,
    this.heroTagPrefix = 'search-tile',
  });

  final String query;
  final List<Movie> movies;
  final MovieListStatus status;
  final MovieSortOption sortOption;
  final ValueChanged<MovieSortOption> onSortOptionChanged;
  final MovieResultPressed onMoviePressed;
  final bool isLoadingMore;
  final String? failureMessage;
  final ScrollController? controller;
  final String heroTagPrefix;

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty && status != MovieListStatus.failure) {
      return MovieResultsEmptyState(query: query);
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount:
          movies.length +
          1 +
          (isLoadingMore ? 1 : 0) +
          (failureMessage != null ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MovieSortChips(
                selectedOption: sortOption,
                onChanged: onSortOptionChanged,
              ),
              const SizedBox(height: 12),
              Text(
                '${movies.length} result${movies.length == 1 ? '' : 's'} for "$query"',
                style: const TextStyle(
                  color: AppColors.iconMuted,
                  fontSize: 13,
                ),
              ),
            ],
          );
        }

        final movieIndex = index - 1;
        if (movieIndex >= movies.length) {
          if (isLoadingMore) return const _MovieResultsPaginationLoader();
          return _MovieResultsErrorBanner(message: failureMessage!);
        }

        final movie = movies[movieIndex];
        final heroTag = '$heroTagPrefix-$movieIndex-${movie.id}';

        return GestureDetector(
          onTap: () => onMoviePressed(movie, heroTag),
          child: MovieResultTile(movie: movie, heroTag: heroTag),
        );
      },
    );
  }
}

class _MovieSortChips extends StatelessWidget {
  const _MovieSortChips({
    required this.selectedOption,
    required this.onChanged,
  });

  final MovieSortOption selectedOption;
  final ValueChanged<MovieSortOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: MovieSortOption.values.map((option) {
          final isActive = option == selectedOption;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(option.label),
              selected: isActive,
              onSelected: (_) => onChanged(option),
              showCheckmark: false,
              selectedColor: AppColors.loginPrimary,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: isActive
                    ? AppColors.loginPrimary
                    : AppColors.surfaceBorder,
              ),
              labelStyle: TextStyle(
                color: isActive ? AppColors.white : AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MovieResultsPaginationLoader extends StatelessWidget {
  const _MovieResultsPaginationLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: AppShimmer(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppShimmerBox(width: 72, height: 10, radius: 5),
            SizedBox(width: 8),
            AppShimmerBox(width: 34, height: 10, radius: 5),
          ],
        ),
      ),
    );
  }
}

class _MovieResultsErrorBanner extends StatelessWidget {
  const _MovieResultsErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.iconMuted, fontSize: 12),
      ),
    );
  }
}
