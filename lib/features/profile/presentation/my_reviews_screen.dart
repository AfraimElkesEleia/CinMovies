import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/core/widgets/app_snack_bar.dart';
import 'package:cinmovies_app/features/movie_details/presentation/model/movie_details_args.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_reviews_tab.dart';
import 'package:cinmovies_app/features/profile/presentation/cubit/my_reviews_cubit.dart';
import 'package:cinmovies_app/features/reviews/data/model/community_review.dart';
import 'package:cinmovies_app/features/reviews/data/review_repository.dart';
import 'package:cinmovies_app/features/reviews/presentation/model/review_replies_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyReviewsScreen extends StatelessWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MyReviewsCubit(serviceLocator<ReviewRepository>())..load(),
      child: const _MyReviewsView(),
    );
  }
}

class _MyReviewsView extends StatelessWidget {
  const _MyReviewsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text('My Reviews'),
      ),
      body: BlocBuilder<MyReviewsCubit, MyReviewsState>(
        builder: (context, state) {
          return RefreshIndicator(
            color: AppColors.loginPrimary,
            backgroundColor: AppColors.surface,
            onRefresh: () => context.read<MyReviewsCubit>().load(),
            child: switch (state.status) {
              MyReviewsStatus.loading || MyReviewsStatus.initial =>
                const _LoadingReviews(),
              MyReviewsStatus.failure => const _MessageList(
                icon: Icons.error_outline_rounded,
                message: 'Could not load your reviews.',
              ),
              MyReviewsStatus.loaded when state.reviews.isEmpty =>
                const _MessageList(
                  icon: Icons.rate_review_outlined,
                  message: 'You have not reviewed any movies yet.',
                ),
              MyReviewsStatus.loaded => ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                itemBuilder: (context, index) {
                  final review = state.reviews[index];
                  return ReviewCard(
                    review: review,
                    showMovie: true,
                    onDeletePressed: (review) =>
                        _deleteReview(context, review),
                    onRepliesPressed: () =>
                        _openReviewReplies(context, review),
                    onMoviePressed: () {
                      context.pushNamed(
                        AppRoutes.movieDetails,
                        arguments: MovieDetailsArgs(
                          movie: review.movie,
                          heroTag: 'my-review-${review.movie.id}',
                        ),
                      );
                    },
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemCount: state.reviews.length,
              ),
            },
          );
        },
      ),
    );
  }

  Future<bool> _deleteReview(BuildContext context, CommunityReview review) async {
    final success = await context.read<MyReviewsCubit>().deleteReview(review);
    if (!context.mounted) return success;

    if (success) {
      AppSnackBar.showSuccess(context, 'Review removed.');
    } else {
      AppSnackBar.showError(context, 'Could not remove your review.');
    }
    return success;
  }

  Future<void> _openReviewReplies(
    BuildContext context,
    CommunityReview review,
  ) async {
    final cubit = context.read<MyReviewsCubit>();
    await context.pushNamed(
      AppRoutes.reviewReplies,
      arguments: ReviewRepliesArgs(review: review),
    );
    if (context.mounted) await cubit.refresh();
  }
}

class _LoadingReviews extends StatelessWidget {
  const _LoadingReviews();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 180),
        const Center(
          child: CircularProgressIndicator(color: AppColors.loginPrimary),
        ),
      ],
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 150),
        Icon(icon, color: AppColors.iconMuted, size: 42),
        const SizedBox(height: 14),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
