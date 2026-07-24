import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/home/data/model/home_movie_model.dart';
import 'package:flutter/material.dart';

class MovieDetailsReviewsTab extends StatelessWidget {
  const MovieDetailsReviewsTab({super.key, required this.reviews});

  final List<MovieReview> reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const Padding(
        key: ValueKey('empty-reviews'),
        padding: EdgeInsets.symmetric(vertical: 38),
        child: Center(
          child: Text(
            'No reviews yet. Be the first!',
            style: TextStyle(color: AppColors.iconMuted, fontSize: 14),
          ),
        ),
      );
    }

    final visibleReviews = reviews.take(3).toList();

    return Padding(
      key: const ValueKey('reviews'),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Column(
        children: [
          for (var index = 0; index < visibleReviews.length; index++) ...[
            MovieReviewCard(review: visibleReviews[index]),
            if (index < visibleReviews.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class MovieReviewCard extends StatelessWidget {
  const MovieReviewCard({super.key, required this.review});

  final MovieReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewHeader(review: review),
          if (review.spoiler) ...[
            const SizedBox(height: 10),
            const _SpoilerBadge(),
          ],
          const SizedBox(height: 10),
          Text(
            review.text,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.surfaceBorder),
          const SizedBox(height: 10),
          _ReviewActions(helpful: review.helpful),
        ],
      ),
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({required this.review});

  final MovieReview review;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipOval(
          child: Image.network(
            review.avatarUrl,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const ColoredBox(
                color: AppColors.surfaceBorder,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                review.username,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                review.date,
                style: const TextStyle(color: AppColors.iconMuted, fontSize: 11),
              ),
            ],
          ),
        ),
        const Icon(Icons.star_rounded, color: AppColors.ratingAmber, size: 14),
        Text(
          review.rating.toStringAsFixed(0),
          style: const TextStyle(
            color: AppColors.ratingAmber,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SpoilerBadge extends StatelessWidget {
  const _SpoilerBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.ratingAmber.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.ratingAmber.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'SPOILER',
        style: TextStyle(
          color: AppColors.ratingAmber,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReviewActions extends StatelessWidget {
  const _ReviewActions({required this.helpful});

  final int helpful;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.thumb_up_alt_outlined,
          color: AppColors.iconMuted,
          size: 15,
        ),
        const SizedBox(width: 6),
        Text(
          '$helpful',
          style: const TextStyle(
            color: AppColors.iconMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 22),
        const Icon(
          Icons.thumb_down_alt_outlined,
          color: AppColors.iconMuted,
          size: 15,
        ),
        const SizedBox(width: 6),
        const Text(
          'Not helpful',
          style: TextStyle(
            color: AppColors.iconMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
