import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';
import 'package:cinmovies_app/features/movie_details/data/movie_details_repository.dart';
import 'package:cinmovies_app/features/reviews/data/model/community_review.dart';
import 'package:cinmovies_app/features/reviews/data/review_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MovieDetailsState extends Equatable {
  const MovieDetailsState({
    required this.status,
    required this.movie,
    this.similarMovies = const [],
    this.isDetailsLoading = false,
    this.isDetailsRefreshing = false,
    this.isFromCache = false,
    this.hasRichDetails = false,
    this.cachedAt,
    this.isReviewsLoading = false,
    this.isFavoriteLoading = false,
    this.isWatchlistLoading = false,
    this.reviews = const [],
    this.isFavorite = false,
    this.inWatchlist = false,
    this.videoKey,
    this.isFavoriteSaving = false,
    this.isWatchlistSaving = false,
    this.isReviewSaving = false,
    this.failure,
  });

  const MovieDetailsState.initial(Movie movie)
    : this(
        status: MovieDetailsStatus.loaded,
        movie: movie,
        isDetailsLoading: true,
        isReviewsLoading: true,
        isFavoriteLoading: true,
        isWatchlistLoading: true,
      );

  final MovieDetailsStatus status;
  final Movie movie;
  final List<Movie> similarMovies;
  final bool isDetailsLoading;
  final bool isDetailsRefreshing;
  final bool isFromCache;
  final bool hasRichDetails;
  final DateTime? cachedAt;
  final bool isReviewsLoading;
  final bool isFavoriteLoading;
  final bool isWatchlistLoading;
  final List<CommunityReview> reviews;
  final bool isFavorite;
  final bool inWatchlist;
  final String? videoKey;
  final bool isFavoriteSaving;
  final bool isWatchlistSaving;
  final bool isReviewSaving;
  final Failure? failure;

  MovieDetailsState copyWith({
    MovieDetailsStatus? status,
    Movie? movie,
    List<Movie>? similarMovies,
    bool? isDetailsLoading,
    bool? isDetailsRefreshing,
    bool? isFromCache,
    bool? hasRichDetails,
    DateTime? cachedAt,
    bool? isReviewsLoading,
    bool? isFavoriteLoading,
    bool? isWatchlistLoading,
    List<CommunityReview>? reviews,
    bool? isFavorite,
    bool? inWatchlist,
    String? videoKey,
    bool? isFavoriteSaving,
    bool? isWatchlistSaving,
    bool? isReviewSaving,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return MovieDetailsState(
      status: status ?? this.status,
      movie: movie ?? this.movie,
      similarMovies: similarMovies ?? this.similarMovies,
      isDetailsLoading: isDetailsLoading ?? this.isDetailsLoading,
      isDetailsRefreshing: isDetailsRefreshing ?? this.isDetailsRefreshing,
      isFromCache: isFromCache ?? this.isFromCache,
      hasRichDetails: hasRichDetails ?? this.hasRichDetails,
      cachedAt: cachedAt ?? this.cachedAt,
      isReviewsLoading: isReviewsLoading ?? this.isReviewsLoading,
      isFavoriteLoading: isFavoriteLoading ?? this.isFavoriteLoading,
      isWatchlistLoading: isWatchlistLoading ?? this.isWatchlistLoading,
      reviews: reviews ?? this.reviews,
      isFavorite: isFavorite ?? this.isFavorite,
      inWatchlist: inWatchlist ?? this.inWatchlist,
      videoKey: videoKey ?? this.videoKey,
      isFavoriteSaving: isFavoriteSaving ?? this.isFavoriteSaving,
      isWatchlistSaving: isWatchlistSaving ?? this.isWatchlistSaving,
      isReviewSaving: isReviewSaving ?? this.isReviewSaving,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    movie,
    similarMovies,
    isDetailsLoading,
    isDetailsRefreshing,
    isFromCache,
    hasRichDetails,
    cachedAt,
    isReviewsLoading,
    isFavoriteLoading,
    isWatchlistLoading,
    reviews,
    isFavorite,
    inWatchlist,
    videoKey,
    isFavoriteSaving,
    isWatchlistSaving,
    isReviewSaving,
    failure,
  ];
}

enum MovieDetailsStatus { loading, loaded, failure }

class MovieDetailsCubit extends Cubit<MovieDetailsState> {
  MovieDetailsCubit(
    this._detailsRepository,
    this._libraryRepository,
    this._reviewRepository,
    Movie movie, {
    this.isGuest = false,
  }) : super(MovieDetailsState.initial(movie));

  final MovieDetailsRepository _detailsRepository;
  final LibraryRepository _libraryRepository;
  final ReviewRepository _reviewRepository;
  final bool isGuest;
  bool _isDetailsRequestInFlight = false;

  Future<void> load() async {
    emit(
      state.copyWith(
        isDetailsLoading: true,
        isReviewsLoading: true,
        isFavoriteLoading: true,
        isWatchlistLoading: true,
        clearFailure: true,
      ),
    );

    await Future.wait([
      _loadDetails(),
      _loadReviews(),
      if (!isGuest) _loadSavedState(UserMovieListType.favorite),
      if (!isGuest) _loadSavedState(UserMovieListType.watchlist),
      if (isGuest) _finishGuestSavedStateLoading(),
    ]);
  }

  Future<void> _finishGuestSavedStateLoading() async {
    if (isClosed) return;
    emit(state.copyWith(isFavoriteLoading: false, isWatchlistLoading: false));
  }

  Future<void> _loadDetails() async {
    if (_isDetailsRequestInFlight) return;
    _isDetailsRequestInFlight = true;

    final cached = _detailsRepository.readCachedMovieDetails(state.movie);
    if (cached != null && !isClosed) {
      emit(
        state.copyWith(
          status: MovieDetailsStatus.loaded,
          movie: cached.data.movie,
          similarMovies: cached.data.similarMovies,
          videoKey: cached.data.videoKey,
          isDetailsLoading: false,
          isDetailsRefreshing: true,
          isFromCache: true,
          hasRichDetails: true,
          cachedAt: cached.cachedAt,
          clearFailure: true,
        ),
      );
    } else if (!isClosed) {
      emit(
        state.copyWith(
          isDetailsLoading: true,
          isDetailsRefreshing: true,
          clearFailure: true,
        ),
      );
    }

    final detailResult = await _detailsRepository.fetchMovieDetails(
      state.movie,
    );
    _isDetailsRequestInFlight = false;
    if (isClosed) return;

    detailResult.fold(
      (failure) => emit(
        state.copyWith(
          status: cached == null
              ? MovieDetailsStatus.failure
              : MovieDetailsStatus.loaded,
          isDetailsLoading: false,
          isDetailsRefreshing: false,
          isFromCache: cached != null,
          hasRichDetails: cached != null,
          failure: failure,
        ),
      ),
      (detail) => emit(
        state.copyWith(
          status: MovieDetailsStatus.loaded,
          movie: detail.movie,
          similarMovies: detail.similarMovies,
          videoKey: detail.videoKey,
          isDetailsLoading: false,
          isDetailsRefreshing: false,
          isFromCache: false,
          hasRichDetails: true,
          cachedAt: DateTime.now().toUtc(),
          clearFailure: true,
        ),
      ),
    );
  }

  Future<void> retryDetails() => _loadDetails();

  Future<void> _loadSavedState(UserMovieListType type) async {
    final result = await _libraryRepository.contains(state.movie, type);
    if (isClosed) return;

    final isListed = result.getOrElse(() => false);
    switch (type) {
      case UserMovieListType.favorite:
        emit(state.copyWith(isFavorite: isListed, isFavoriteLoading: false));
      case UserMovieListType.watchlist:
        emit(state.copyWith(inWatchlist: isListed, isWatchlistLoading: false));
      case UserMovieListType.watched:
        break;
    }
  }

  Future<void> _loadReviews() async {
    final result = await _reviewRepository.reviewsForMovie(state.movie);
    if (isClosed) return;

    result.fold(
      (_) => emit(state.copyWith(isReviewsLoading: false)),
      (reviews) =>
          emit(state.copyWith(reviews: reviews, isReviewsLoading: false)),
    );
  }

  Future<bool> toggleFavorite() {
    if (isGuest || state.isFavoriteLoading || state.isFavoriteSaving) {
      return Future.value(false);
    }

    final current = state.isFavorite;
    return _toggle(
      type: UserMovieListType.favorite,
      current: current,
      emitBusy: (isSaving, value) =>
          emit(state.copyWith(isFavoriteSaving: isSaving, isFavorite: value)),
    );
  }

  Future<bool> toggleWatchlist() {
    if (isGuest || state.isWatchlistLoading || state.isWatchlistSaving) {
      return Future.value(false);
    }

    final current = state.inWatchlist;
    return _toggle(
      type: UserMovieListType.watchlist,
      current: current,
      emitBusy: (isSaving, value) =>
          emit(state.copyWith(isWatchlistSaving: isSaving, inWatchlist: value)),
    );
  }

  Future<bool> toggleReviewReaction(
    CommunityReview review,
    ReviewReaction reaction,
  ) async {
    if (isGuest || review.isOwnReview) return false;

    final previousReviews = state.reviews;
    final nextReviews = previousReviews
        .map(
          (item) => item.id == review.id
              ? _reviewWithToggledReaction(item, reaction)
              : item,
        )
        .toList();
    emit(state.copyWith(reviews: nextReviews));

    final previousReaction = review.currentUserReaction;
    final result = previousReaction == reaction
        ? await _reviewRepository.clearReaction(review.id)
        : await _reviewRepository.setReaction(
            reviewId: review.id,
            reaction: reaction,
          );

    return result.fold((_) {
      emit(state.copyWith(reviews: previousReviews));
      return false;
    }, (_) => true);
  }

  Future<bool> deleteReview(CommunityReview review) async {
    if (isGuest || !review.isOwnReview) return false;

    final previousReviews = state.reviews;
    emit(
      state.copyWith(
        reviews: previousReviews.where((item) => item.id != review.id).toList(),
      ),
    );

    final result = await _reviewRepository.deleteReview(review.id);
    return result.fold((_) {
      emit(state.copyWith(reviews: previousReviews));
      return false;
    }, (_) => true);
  }

  Future<bool> submitReview({
    required double rating,
    String? title,
    required String body,
    required bool spoiler,
  }) async {
    if (isGuest || state.isReviewSaving) return false;

    emit(state.copyWith(isReviewSaving: true, clearFailure: true));
    final result = await _reviewRepository.upsertReview(
      movie: state.movie,
      rating: rating,
      title: title?.trim().isEmpty == true ? null : title?.trim(),
      body: body.trim(),
      spoiler: spoiler,
    );
    if (isClosed) return false;

    return result.fold(
      (failure) {
        emit(state.copyWith(isReviewSaving: false, failure: failure));
        return false;
      },
      (_) async {
        await _loadReviews();
        if (!isClosed) {
          emit(state.copyWith(isReviewSaving: false));
        }
        return true;
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

  Future<bool> _toggle({
    required UserMovieListType type,
    required bool current,
    required void Function(bool isSaving, bool value) emitBusy,
  }) async {
    final nextValue = !current;
    emitBusy(true, nextValue);
    try {
      final result = await _libraryRepository.setListed(
        state.movie,
        type,
        listed: nextValue,
      );
      return result.fold(
        (_) {
          emitBusy(false, current);
          return false;
        },
        (_) {
          emitBusy(false, nextValue);
          return true;
        },
      );
    } catch (_) {
      emitBusy(false, current);
      return false;
    }
  }
}
