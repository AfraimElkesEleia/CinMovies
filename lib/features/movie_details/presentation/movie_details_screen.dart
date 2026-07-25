import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/core/widgets/app_snack_bar.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';
import 'package:cinmovies_app/features/movie_details/data/movie_details_repository.dart';
import 'package:cinmovies_app/features/movie_details/presentation/cubit/movie_details_cubit.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_backdrop.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_info.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_reviews_tab.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_tab_content.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_tabs.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/similar_movies_section.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/trailer_overlay.dart';
import 'package:cinmovies_app/features/reviews/data/model/app_review.dart';
import 'package:cinmovies_app/features/reviews/data/review_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MovieDetailsScreen extends StatelessWidget {
  const MovieDetailsScreen({
    super.key,
    required this.movie,
    required this.heroTag,
  });

  final Movie movie;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MovieDetailsCubit(
        sl<MovieDetailsRepository>(),
        sl<LibraryRepository>(),
        sl<ReviewRepository>(),
        movie,
      )..load(),
      child: _MovieDetailsView(heroTag: heroTag),
    );
  }
}

class _MovieDetailsView extends StatelessWidget {
  const _MovieDetailsView({required this.heroTag});

  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MovieDetailsCubit, MovieDetailsState>(
      builder: (context, state) {
        final cubit = context.read<MovieDetailsCubit>();
        final movie = state.movie;

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: MovieDetailsBackdrop(
                      movie: movie,
                      heroTag: heroTag,
                      isFavorite: state.isFavorite,
                      isFavoriteLoading:
                          state.isFavoriteLoading || state.isFavoriteSaving,
                      onBackPressed: Navigator.of(context).pop,
                      onFavoritePressed: () => _toggleFavorite(context),
                      onSharePressed: _shareMovie,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: MovieDetailsInfo(
                      movie: movie,
                      inWatchlist: state.inWatchlist,
                      isWatchlistLoading:
                          state.isWatchlistLoading || state.isWatchlistSaving,
                      onTrailerPressed: cubit.showTrailer,
                      onWatchlistPressed: () => _toggleWatchlist(context),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: MovieDetailsTabs(
                      activeTab: state.activeTab,
                      onTabSelected: cubit.selectTab,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: MovieDetailsTabContent(
                      activeTab: state.activeTab,
                      movie: movie,
                      reviews: state.reviews,
                      isReviewsLoading: state.isReviewsLoading,
                      isReviewSaving: state.isReviewSaving,
                      onWriteReviewPressed: () => _writeReview(context),
                      onReviewReactionPressed: (review, reaction) =>
                          cubit.toggleReviewReaction(review, reaction),
                      onReviewDeletePressed: (review) =>
                          _deleteReview(context, review),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SimilarMoviesSection(
                      movies: state.similarMovies,
                      onMoviePressed: (movie, heroTag) =>
                          _openSimilarMovie(context, movie, heroTag),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 30)),
                ],
              ),
              if (state.showTrailer)
                TrailerOverlay(movie: movie, onClose: cubit.hideTrailer),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    final success = await context.read<MovieDetailsCubit>().toggleFavorite();
    if (!success && context.mounted) {
      AppSnackBar.showInfo(context, 'Sign in to update your favorite movies.');
    }
  }

  Future<void> _toggleWatchlist(BuildContext context) async {
    final success = await context.read<MovieDetailsCubit>().toggleWatchlist();
    if (!success && context.mounted) {
      AppSnackBar.showInfo(context, 'Sign in to update your watchlist.');
    }
  }

  Future<void> _writeReview(BuildContext context) async {
    final request = await showModalBottomSheet<ReviewComposerRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => const ReviewComposerSheet(),
    );
    if (request == null || !context.mounted) return;

    final success = await context.read<MovieDetailsCubit>().submitReview(
      rating: request.rating,
      title: request.title,
      body: request.body,
      spoiler: request.spoiler,
    );
    if (!context.mounted) return;

    if (success) {
      AppSnackBar.showSuccess(context, 'Review saved.');
    } else {
      AppSnackBar.showError(context, 'Could not save your review.');
    }
  }

  Future<bool> _deleteReview(BuildContext context, AppReview review) async {
    final success = await context.read<MovieDetailsCubit>().deleteReview(review);
    if (!context.mounted) return success;

    if (success) {
      AppSnackBar.showSuccess(context, 'Review removed.');
    } else {
      AppSnackBar.showError(context, 'Could not remove your review.');
    }
    return success;
  }

  void _openSimilarMovie(BuildContext context, Movie movie, String heroTag) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MovieDetailsScreen(
          movie: movie,
          heroTag: heroTag,
        ),
      ),
    );
  }

  void _shareMovie() {}
}
