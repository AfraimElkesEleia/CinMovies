import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/core/widgets/app_shimmer.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
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
    this.isLoadingMore = false,
    this.failureMessage,
    this.controller,
    this.onMoviePressed,
  });

  final String query;
  final List<HomeMovieModel> movies;
  final SearchStatus status;
  final bool isLoadingMore;
  final String? failureMessage;
  final ScrollController? controller;
  final ValueChanged<HomeMovieModel>? onMoviePressed;

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
          return Text(
            '${movies.length} result${movies.length == 1 ? '' : 's'} for "$query"',
            style: const TextStyle(color: AppColors.iconMuted, fontSize: 13),
          );
        }

        final movieIndex = index - 1;
        if (movieIndex >= movies.length) {
          if (isLoadingMore) return const _SearchBottomLoader();
          return _SearchErrorBanner(message: failureMessage!);
        }

        final movie = movies[movieIndex];

        return GestureDetector(
          onTap: () async {
            onMoviePressed?.call(movie);
            context.pushNamed(Routes.movieDetails, arguments: movie);
          },
          child: SearchMovieTile(movie: movie),
        );
      },
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
