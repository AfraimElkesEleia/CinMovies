import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/movie_details/presentation/model/movie_details_tab.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_cast_tab.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_overview_tab.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_reviews_tab.dart';
import 'package:cinmovies_app/features/reviews/data/model/community_review.dart';
import 'package:flutter/material.dart';

class MovieDetailsTabContent extends StatelessWidget {
  const MovieDetailsTabContent({
    super.key,
    required this.activeTab,
    required this.movie,
    required this.reviews,
    required this.isReviewsLoading,
    required this.isReviewSaving,
    required this.onWriteReviewPressed,
    required this.onReviewReactionPressed,
    required this.onReviewDeletePressed,
  });

  final MovieDetailsTab activeTab;
  final Movie movie;
  final List<CommunityReview> reviews;
  final bool isReviewsLoading;
  final bool isReviewSaving;
  final VoidCallback onWriteReviewPressed;
  final Future<bool> Function(CommunityReview review, ReviewReaction reaction)
  onReviewReactionPressed;
  final Future<bool> Function(CommunityReview review) onReviewDeletePressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: switch (activeTab) {
        MovieDetailsTab.overview => MovieDetailsOverviewTab(movie: movie),
        MovieDetailsTab.cast => MovieDetailsCastTab(cast: movie.cast),
        MovieDetailsTab.reviews => MovieDetailsReviewsTab(
          reviews: reviews,
          isLoading: isReviewsLoading,
          isReviewSaving: isReviewSaving,
          onWriteReviewPressed: onWriteReviewPressed,
          onReactionPressed: onReviewReactionPressed,
          onDeletePressed: onReviewDeletePressed,
        ),
      },
    );
  }
}
