import 'package:cinmovies_app/core/error/app_error.dart';
import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/features/reviews/data/model/community_review.dart';
import 'package:cinmovies_app/features/reviews/data/model/review_reply.dart';
import 'package:cinmovies_app/features/reviews/data/review_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ReviewRepliesStatus { initial, loading, loaded, failure }

class ReviewRepliesState extends Equatable {
  const ReviewRepliesState({
    required this.review,
    this.status = ReviewRepliesStatus.initial,
    this.replies = const [],
    this.isReplySaving = false,
    this.failure,
  });

  final CommunityReview review;
  final ReviewRepliesStatus status;
  final List<ReviewReply> replies;
  final bool isReplySaving;
  final AppError? failure;

  ReviewRepliesState copyWith({
    CommunityReview? review,
    ReviewRepliesStatus? status,
    List<ReviewReply>? replies,
    bool? isReplySaving,
    AppError? failure,
    bool clearFailure = false,
  }) {
    return ReviewRepliesState(
      review: review ?? this.review,
      status: status ?? this.status,
      replies: replies ?? this.replies,
      isReplySaving: isReplySaving ?? this.isReplySaving,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [review, status, replies, isReplySaving, failure];
}

class ReviewRepliesCubit extends Cubit<ReviewRepliesState> {
  ReviewRepliesCubit(
    this._reviewRepository,
    CommunityReview review, {
    this.isGuest = false,
  }) : super(ReviewRepliesState(review: review));

  final ReviewRepository _reviewRepository;
  final bool isGuest;

  Future<void> load() async {
    emit(
      state.copyWith(status: ReviewRepliesStatus.loading, clearFailure: true),
    );
    final result = await _reviewRepository.repliesForReview(state.review.id);
    if (isClosed) return;

    result.when(
      onSuccess: (replies) => emit(
        state.copyWith(
          status: ReviewRepliesStatus.loaded,
          replies: replies,
          review: state.review.copyWith(replyCount: replies.length),
          clearFailure: true,
        ),
      ),
      onFailure: (error) => emit(
        state.copyWith(status: ReviewRepliesStatus.failure, failure: error),
      ),
    );
  }

  Future<bool> submitReply(String body) async {
    final value = body.trim();
    if (isGuest ||
        state.isReplySaving ||
        value.isEmpty ||
        value.length > 1000) {
      return false;
    }

    emit(state.copyWith(isReplySaving: true, clearFailure: true));
    final result = await _reviewRepository.createReply(
      reviewId: state.review.id,
      body: value,
    );
    if (isClosed) return false;

    AppError? createError;
    var created = false;
    result.when(
      onSuccess: (_) => created = true,
      onFailure: (error) => createError = error,
    );
    if (!created) {
      emit(state.copyWith(isReplySaving: false, failure: createError));
      return false;
    }

    final refreshed = await _reviewRepository.repliesForReview(state.review.id);
    if (isClosed) return true;
    refreshed.when(
      onSuccess: (replies) => emit(
        state.copyWith(
          status: ReviewRepliesStatus.loaded,
          replies: replies,
          review: state.review.copyWith(replyCount: replies.length),
          isReplySaving: false,
          clearFailure: true,
        ),
      ),
      onFailure: (error) => emit(
        state.copyWith(
          isReplySaving: false,
          review: state.review.copyWith(
            replyCount: state.review.replyCount + 1,
          ),
          failure: error,
        ),
      ),
    );
    return true;
  }

  Future<bool> toggleReviewReaction(ReviewReaction reaction) async {
    final review = state.review;
    if (isGuest || review.isOwnReview) return false;

    final nextReview = _reviewWithToggledReaction(review, reaction);
    emit(state.copyWith(review: nextReview));
    final result = review.currentUserReaction == reaction
        ? await _reviewRepository.clearReaction(review.id)
        : await _reviewRepository.setReaction(
            reviewId: review.id,
            reaction: reaction,
          );
    if (isClosed) return false;

    return result.when(
      onSuccess: (_) => true,
      onFailure: (_) {
        emit(state.copyWith(review: review));
        return false;
      },
    );
  }

  Future<bool> toggleReplyReaction(
    ReviewReply reply,
    ReviewReaction reaction,
  ) async {
    if (isGuest || reply.isOwnReply) return false;

    final previousReplies = state.replies;
    emit(
      state.copyWith(
        replies: previousReplies
            .map(
              (item) => item.id == reply.id
                  ? _replyWithToggledReaction(item, reaction)
                  : item,
            )
            .toList(),
      ),
    );
    final result = reply.currentUserReaction == reaction
        ? await _reviewRepository.clearReplyReaction(reply.id)
        : await _reviewRepository.setReplyReaction(
            replyId: reply.id,
            reaction: reaction,
          );
    if (isClosed) return false;

    return result.when(
      onSuccess: (_) => true,
      onFailure: (_) {
        emit(state.copyWith(replies: previousReplies));
        return false;
      },
    );
  }

  Future<bool> deleteReply(ReviewReply reply) async {
    if (isGuest || !reply.isOwnReply) return false;

    final previousReplies = state.replies;
    final previousReview = state.review;
    emit(
      state.copyWith(
        replies: previousReplies.where((item) => item.id != reply.id).toList(),
        review: previousReview.copyWith(
          replyCount: previousReview.replyCount > 0
              ? previousReview.replyCount - 1
              : 0,
        ),
      ),
    );
    final result = await _reviewRepository.deleteReply(reply.id);
    if (isClosed) return false;

    return result.when(
      onSuccess: (_) => true,
      onFailure: (_) {
        emit(state.copyWith(replies: previousReplies, review: previousReview));
        return false;
      },
    );
  }

  CommunityReview _reviewWithToggledReaction(
    CommunityReview review,
    ReviewReaction nextReaction,
  ) {
    final previousReaction = review.currentUserReaction;
    var likeCount = review.likeCount;
    var dislikeCount = review.dislikeCount;

    if (previousReaction == ReviewReaction.like) likeCount--;
    if (previousReaction == ReviewReaction.dislike) dislikeCount--;
    if (previousReaction == nextReaction) {
      return review.copyWith(
        likeCount: likeCount,
        dislikeCount: dislikeCount,
        clearCurrentUserReaction: true,
      );
    }
    if (nextReaction == ReviewReaction.like) likeCount++;
    if (nextReaction == ReviewReaction.dislike) dislikeCount++;
    return review.copyWith(
      likeCount: likeCount,
      dislikeCount: dislikeCount,
      currentUserReaction: nextReaction,
    );
  }

  ReviewReply _replyWithToggledReaction(
    ReviewReply reply,
    ReviewReaction nextReaction,
  ) {
    final previousReaction = reply.currentUserReaction;
    var likeCount = reply.likeCount;
    var dislikeCount = reply.dislikeCount;

    if (previousReaction == ReviewReaction.like) likeCount--;
    if (previousReaction == ReviewReaction.dislike) dislikeCount--;
    if (previousReaction == nextReaction) {
      return reply.copyWith(
        likeCount: likeCount,
        dislikeCount: dislikeCount,
        clearCurrentUserReaction: true,
      );
    }
    if (nextReaction == ReviewReaction.like) likeCount++;
    if (nextReaction == ReviewReaction.dislike) dislikeCount++;
    return reply.copyWith(
      likeCount: likeCount,
      dislikeCount: dislikeCount,
      currentUserReaction: nextReaction,
    );
  }
}
