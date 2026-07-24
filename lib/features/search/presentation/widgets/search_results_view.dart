import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/core/widgets/app_shimmer.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/movie_details/data/model/movie_details_args.dart';
import 'package:cinmovies_app/features/search/presentation/cubit/search_cubit.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_empty_state.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_movie_tile.dart';
import 'package:flutter/material.dart';

class SearchResultsView extends StatelessWidget {
  const SearchResultsView({
    super.key,
    required this.query,
    required this.movies,
    required this.status,
    required this.sortMode,
    required this.onSortModeChanged,
    this.isLoadingMore = false,
    this.failureMessage,
    this.controller,
    this.onMoviePressed,
  });

  final String query;
  final List<Movie> movies;
  final SearchStatus status;
  final SearchSortMode sortMode;
  final ValueChanged<SearchSortMode> onSortModeChanged;
  final bool isLoadingMore;
  final String? failureMessage;
  final ScrollController? controller;
  final ValueChanged<Movie>? onMoviePressed;

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty && status != SearchStatus.failure) {
      return SearchEmptyState(query: query);
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
              _SearchSortChips(
                activeMode: sortMode,
                onChanged: onSortModeChanged,
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
          if (isLoadingMore) return const _SearchBottomLoader();
          return _SearchErrorBanner(message: failureMessage!);
        }

        final movie = movies[movieIndex];
        final heroTag = 'search-tile-$movieIndex-${movie.id}';

        return GestureDetector(
          onTap: () async {
            onMoviePressed?.call(movie);
            context.pushNamed(
              Routes.movieDetails,
              arguments: MovieDetailsArgs(movie: movie, heroTag: heroTag),
            );
          },
          child: SearchMovieTile(movie: movie, heroTag: heroTag),
        );
      },
    );
  }
}

class _SearchSortChips extends StatelessWidget {
  const _SearchSortChips({required this.activeMode, required this.onChanged});

  final SearchSortMode activeMode;
  final ValueChanged<SearchSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: SearchSortMode.values.map((mode) {
          final isActive = mode == activeMode;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(mode.label),
              selected: isActive,
              onSelected: (_) => onChanged(mode),
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

class _SearchBottomLoader extends StatelessWidget {
  const _SearchBottomLoader();

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

class _SearchErrorBanner extends StatelessWidget {
  const _SearchErrorBanner({required this.message});

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
