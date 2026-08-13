import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/reviews/data/model/community_review.dart';
import 'package:cinmovies_app/features/reviews/data/model/review_reply.dart';
import 'package:cinmovies_app/features/reviews/data/review_repository.dart';
import 'package:cinmovies_app/features/reviews/presentation/cubit/review_replies_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('load exposes replies and replaces the card reply count', () async {
    final repository = _FakeReviewRepository()
      ..replies = [_reply('reply-1'), _reply('reply-2')];
    final cubit = ReviewRepliesCubit(repository, _review(replyCount: 8));
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.status, ReviewRepliesStatus.loaded);
    expect(cubit.state.replies, hasLength(2));
    expect(cubit.state.review.replyCount, 2);
  });

  test('successful submission reloads replies and updates the count', () async {
    final repository = _FakeReviewRepository();
    final cubit = ReviewRepliesCubit(repository, _review());
    addTearDown(cubit.close);

    await cubit.load();
    final success = await cubit.submitReply('  New reply  ');

    expect(success, isTrue);
    expect(repository.createdBodies, ['New reply']);
    expect(cubit.state.replies.single.body, 'New reply');
    expect(cubit.state.review.replyCount, 1);
  });

  test('guest cannot submit or react', () async {
    final repository = _FakeReviewRepository();
    final reply = _reply('reply-1');
    final cubit = ReviewRepliesCubit(repository, _review(), isGuest: true);
    addTearDown(cubit.close);

    expect(await cubit.submitReply('Blocked'), isFalse);
    expect(
      await cubit.toggleReplyReaction(reply, ReviewReaction.like),
      isFalse,
    );
    expect(repository.createdBodies, isEmpty);
    expect(repository.replyReactionCalls, 0);
  });

  test('reply reactions toggle optimistically and persist', () async {
    final repository = _FakeReviewRepository()..replies = [_reply('reply-1')];
    final cubit = ReviewRepliesCubit(repository, _review());
    addTearDown(cubit.close);
    await cubit.load();

    final success = await cubit.toggleReplyReaction(
      cubit.state.replies.single,
      ReviewReaction.like,
    );

    expect(success, isTrue);
    expect(cubit.state.replies.single.likeCount, 1);
    expect(cubit.state.replies.single.currentUserReaction, ReviewReaction.like);
    expect(repository.replyReactionCalls, 1);
  });

  test('authors can delete their own reply and count is decremented', () async {
    final ownReply = _reply('reply-1', isOwnReply: true);
    final repository = _FakeReviewRepository()..replies = [ownReply];
    final cubit = ReviewRepliesCubit(repository, _review(replyCount: 1));
    addTearDown(cubit.close);
    await cubit.load();

    final success = await cubit.deleteReply(cubit.state.replies.single);

    expect(success, isTrue);
    expect(cubit.state.replies, isEmpty);
    expect(cubit.state.review.replyCount, 0);
    expect(repository.deletedReplyIds, ['reply-1']);
  });
}

class _FakeReviewRepository implements ReviewRepository {
  List<ReviewReply> replies = [];
  final List<String> createdBodies = [];
  final List<String> deletedReplyIds = [];
  int replyReactionCalls = 0;

  @override
  Future<Result<List<ReviewReply>>> repliesForReview(String reviewId) async {
    return Success(List.of(replies));
  }

  @override
  Future<Result<void>> createReply({
    required String reviewId,
    required String body,
  }) async {
    createdBodies.add(body);
    replies = [
      ...replies,
      _reply('reply-${replies.length + 1}', body: body, isOwnReply: true),
    ];
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteReply(String replyId) async {
    deletedReplyIds.add(replyId);
    replies = replies.where((reply) => reply.id != replyId).toList();
    return const Success(null);
  }

  @override
  Future<Result<void>> setReplyReaction({
    required String replyId,
    required ReviewReaction reaction,
  }) async {
    replyReactionCalls++;
    return const Success(null);
  }

  @override
  Future<Result<void>> clearReplyReaction(String replyId) async {
    return const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CommunityReview _review({int replyCount = 0}) {
  return CommunityReview(
    id: 'review-1',
    movie: _movie(),
    authorId: 'author-1',
    authorName: 'Reviewer',
    authorAvatarUrl: '',
    rating: 8,
    title: 'A review',
    body: 'Review body',
    spoiler: false,
    createdAt: DateTime.utc(2026, 8, 1),
    likeCount: 0,
    dislikeCount: 0,
    currentUserReaction: null,
    isOwnReview: false,
    replyCount: replyCount,
  );
}

ReviewReply _reply(
  String id, {
  String body = 'Reply body',
  bool isOwnReply = false,
}) {
  return ReviewReply(
    id: id,
    reviewId: 'review-1',
    authorId: isOwnReply ? 'current-user' : 'author-2',
    authorName: 'Reply author',
    authorAvatarUrl: '',
    body: body,
    createdAt: DateTime.utc(2026, 8, 2),
    likeCount: 0,
    dislikeCount: 0,
    currentUserReaction: null,
    isOwnReply: isOwnReply,
  );
}

Movie _movie() {
  return const Movie(
    id: '1',
    title: 'Movie',
    imageAsset: 'assets/images/movie_ex1.jpg',
    genres: [],
    rating: 8,
    year: '2026',
    duration: '2h',
    ageRating: 'PG-13',
    synopsis: 'Synopsis',
    director: 'Director',
    votes: '1K',
    cast: [],
    reviews: [],
  );
}
