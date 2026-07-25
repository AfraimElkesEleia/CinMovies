import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/reviews/data/model/app_review.dart';
import 'package:flutter/material.dart';

class MovieDetailsReviewsTab extends StatelessWidget {
  const MovieDetailsReviewsTab({
    super.key,
    required this.reviews,
    required this.isLoading,
    required this.isReviewSaving,
    required this.onWriteReviewPressed,
    required this.onReactionPressed,
    required this.onDeletePressed,
  });

  final List<AppReview> reviews;
  final bool isLoading;
  final bool isReviewSaving;
  final VoidCallback onWriteReviewPressed;
  final Future<bool> Function(AppReview review, ReviewReaction reaction)
  onReactionPressed;
  final Future<bool> Function(AppReview review) onDeletePressed;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        key: ValueKey('loading-reviews'),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 38),
        child: Column(
          children: [
            _WriteReviewButton(
              isSaving: isReviewSaving,
              onPressed: onWriteReviewPressed,
            ),
            const SizedBox(height: 30),
            const Center(
              child: CircularProgressIndicator(color: AppColors.loginPrimary),
            ),
          ],
        ),
      );
    }

    if (reviews.isEmpty) {
      return Padding(
        key: ValueKey('empty-reviews'),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 38),
        child: Column(
          children: [
            _WriteReviewButton(
              isSaving: isReviewSaving,
              onPressed: onWriteReviewPressed,
            ),
            const SizedBox(height: 28),
            const Center(
              child: Text(
                'No reviews yet. Be the first!',
                style: TextStyle(color: AppColors.iconMuted, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    final visibleReviews = reviews.take(10).toList();

    return Padding(
      key: const ValueKey('reviews'),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Column(
        children: [
          _WriteReviewButton(
            isSaving: isReviewSaving,
            onPressed: onWriteReviewPressed,
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < visibleReviews.length; index++) ...[
            ReviewCard(
              review: visibleReviews[index],
              onReactionPressed: onReactionPressed,
              onDeletePressed: onDeletePressed,
            ),
            if (index < visibleReviews.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class ReviewComposerRequest {
  const ReviewComposerRequest({
    required this.rating,
    required this.title,
    required this.body,
    required this.spoiler,
  });

  final double rating;
  final String? title;
  final String body;
  final bool spoiler;
}

class ReviewComposerSheet extends StatefulWidget {
  const ReviewComposerSheet({super.key});

  @override
  State<ReviewComposerSheet> createState() => _ReviewComposerSheetState();
}

class _ReviewComposerSheetState extends State<ReviewComposerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  double _rating = 8;
  bool _spoiler = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(
            top: BorderSide(color: AppColors.surfaceBorder),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Write Review',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: Navigator.of(context).pop,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _RatingControl(
                    rating: _rating,
                    onChanged: (value) => setState(() => _rating = value),
                  ),
                  const SizedBox(height: 16),
                  _ReviewTextField(
                    controller: _titleController,
                    label: 'Title',
                    hint: 'Short summary',
                    maxLines: 1,
                  ),
                  const SizedBox(height: 12),
                  _ReviewTextField(
                    controller: _bodyController,
                    label: 'Review',
                    hint: 'Share what you thought about this movie',
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Write your review first.';
                      }
                      if (value.trim().length < 8) {
                        return 'Write at least 8 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _spoiler,
                    onChanged: (value) =>
                        setState(() => _spoiler = value ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.loginPrimary,
                    checkColor: AppColors.white,
                    title: const Text(
                      'Contains spoilers',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.rate_review_rounded, size: 18),
                      label: const Text('Save Review'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.loginPrimary,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ReviewComposerRequest(
        rating: _rating,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        body: _bodyController.text.trim(),
        spoiler: _spoiler,
      ),
    );
  }
}

class _WriteReviewButton extends StatelessWidget {
  const _WriteReviewButton({
    required this.isSaving,
    required this.onPressed,
  });

  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: isSaving ? null : onPressed,
        icon: isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : const Icon(Icons.edit_note_rounded, size: 20),
        label: Text(isSaving ? 'Saving...' : 'Write a Review'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.loginPrimary,
          disabledBackgroundColor: AppColors.loginPrimaryDark,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _RatingControl extends StatelessWidget {
  const _RatingControl({
    required this.rating,
    required this.onChanged,
  });

  final double rating;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: AppColors.ratingAmber,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Rating',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppColors.ratingAmber,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Slider(
            value: rating,
            min: 0,
            max: 10,
            divisions: 20,
            activeColor: AppColors.loginPrimary,
            inactiveColor: AppColors.surfaceBorder,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ReviewTextField extends StatelessWidget {
  const _ReviewTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.maxLines,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      minLines: maxLines == 1 ? 1 : 4,
      validator: validator,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textDisabled),
        errorStyle: const TextStyle(color: AppColors.loginPrimary),
        filled: true,
        fillColor: AppColors.scaffoldBackground,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.loginPrimary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.loginPrimaryDark),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.loginPrimary),
        ),
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.review,
    this.showMovie = false,
    this.onMoviePressed,
    this.onReactionPressed,
    this.onDeletePressed,
  });

  final AppReview review;
  final bool showMovie;
  final VoidCallback? onMoviePressed;
  final Future<bool> Function(AppReview review, ReviewReaction reaction)?
  onReactionPressed;
  final Future<bool> Function(AppReview review)? onDeletePressed;

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
          if (showMovie) ...[
            _ReviewMovieHeader(review: review, onPressed: onMoviePressed),
            const SizedBox(height: 12),
            Container(height: 1, color: AppColors.surfaceBorder),
            const SizedBox(height: 12),
          ],
          _ReviewHeader(review: review),
          if (review.spoiler) ...[
            const SizedBox(height: 10),
            const _SpoilerBadge(),
          ],
          if (review.title?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              review.title!,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            review.displayText,
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
          _ReviewActions(
            review: review,
            onReactionPressed: onReactionPressed,
            onDeletePressed: onDeletePressed,
          ),
        ],
      ),
    );
  }
}

class _ReviewMovieHeader extends StatelessWidget {
  const _ReviewMovieHeader({required this.review, this.onPressed});

  final AppReview review;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _PosterImage(path: review.movie.imageAsset),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  review.movie.year,
                  style: const TextStyle(
                    color: AppColors.iconMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onPressed != null)
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.iconMuted,
              size: 22,
            ),
        ],
      ),
    );
  }
}

class _PosterImage extends StatelessWidget {
  const _PosterImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    const size = Size(42, 58);
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: size.width,
        height: size.height,
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      path,
      width: size.width,
      height: size.height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const ColoredBox(
        color: AppColors.surfaceBorder,
        child: SizedBox(
          width: 42,
          height: 58,
          child: Icon(
            Icons.movie_creation_outlined,
            color: AppColors.textMuted,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({required this.review});

  final AppReview review;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipOval(
          child: Image.network(
            review.authorAvatarUrl,
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
                review.authorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                review.displayDate,
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
  const _ReviewActions({
    required this.review,
    required this.onReactionPressed,
    required this.onDeletePressed,
  });

  final AppReview review;
  final Future<bool> Function(AppReview review, ReviewReaction reaction)?
  onReactionPressed;
  final Future<bool> Function(AppReview review)? onDeletePressed;

  @override
  Widget build(BuildContext context) {
    final canReact = onReactionPressed != null && !review.isOwnReview;
    return Row(
      children: [
        _ReactionButton(
          icon: Icons.thumb_up_alt_outlined,
          selectedIcon: Icons.thumb_up_alt_rounded,
          label: review.likeCount.toString(),
          selected: review.currentUserReaction == ReviewReaction.like,
          enabled: canReact,
          onPressed: () => onReactionPressed?.call(review, ReviewReaction.like),
        ),
        const SizedBox(width: 18),
        _ReactionButton(
          icon: Icons.thumb_down_alt_outlined,
          selectedIcon: Icons.thumb_down_alt_rounded,
          label: review.dislikeCount.toString(),
          selected: review.currentUserReaction == ReviewReaction.dislike,
          enabled: canReact,
          onPressed: () =>
              onReactionPressed?.call(review, ReviewReaction.dislike),
        ),
        if (review.isOwnReview && onDeletePressed != null) ...[
          const Spacer(),
          InkWell(
            onTap: () => onDeletePressed?.call(review),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.loginPrimary,
                size: 18,
              ),
            ),
          ),
        ] else if (review.isOwnReview) ...[
          const Spacer(),
          const Text(
            'Your review',
            style: TextStyle(
              color: AppColors.iconMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.loginPrimary : AppColors.iconMuted;
    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
