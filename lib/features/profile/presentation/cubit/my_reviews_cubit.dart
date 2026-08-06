import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/features/reviews/data/model/community_review.dart';
import 'package:cinmovies_app/features/reviews/data/review_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum MyReviewsStatus { initial, loading, loaded, failure }

class MyReviewsState extends Equatable {
  const MyReviewsState({
    this.status = MyReviewsStatus.initial,
    this.reviews = const [],
    this.failure,
  });

  final MyReviewsStatus status;
  final List<CommunityReview> reviews;
  final Failure? failure;

  MyReviewsState copyWith({
    MyReviewsStatus? status,
    List<CommunityReview>? reviews,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return MyReviewsState(
      status: status ?? this.status,
      reviews: reviews ?? this.reviews,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [status, reviews, failure];
}

class MyReviewsCubit extends Cubit<MyReviewsState> {
  MyReviewsCubit(this._reviewRepository) : super(const MyReviewsState());

  final ReviewRepository _reviewRepository;

  Future<void> load() async {
    emit(state.copyWith(status: MyReviewsStatus.loading, clearFailure: true));
    final result = await _reviewRepository.reviewsForCurrentUser();
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: MyReviewsStatus.failure,
          failure: failure,
        ),
      ),
      (reviews) => emit(
        state.copyWith(
          status: MyReviewsStatus.loaded,
          reviews: reviews,
          clearFailure: true,
        ),
      ),
    );
  }

  Future<bool> deleteReview(CommunityReview review) async {
    final previousReviews = state.reviews;
    emit(
      state.copyWith(
        reviews: previousReviews
            .where((item) => item.id != review.id)
            .toList(),
      ),
    );

    final result = await _reviewRepository.deleteReview(review.id);
    return result.fold(
      (_) {
        emit(state.copyWith(reviews: previousReviews));
        return false;
      },
      (_) => true,
    );
  }

  Future<void> refresh() async {
    final result = await _reviewRepository.reviewsForCurrentUser();
    if (isClosed) return;
    result.fold(
      (_) {},
      (reviews) => emit(
        state.copyWith(
          status: MyReviewsStatus.loaded,
          reviews: reviews,
          clearFailure: true,
        ),
      ),
    );
  }
}
