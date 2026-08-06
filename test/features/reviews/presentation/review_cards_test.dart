import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_reviews_tab.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/reviews/data/model/community_review.dart';
import 'package:cinmovies_app/features/reviews/data/model/review_reply.dart';
import 'package:cinmovies_app/features/reviews/presentation/review_replies_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('review card shows reply count and opens the thread', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReviewCard(
            review: _review(replyCount: 7),
            onRepliesPressed: () => opened = true,
          ),
        ),
      ),
    );

    expect(find.text('7'), findsOneWidget);
    await tester.tap(find.text('Review body'));

    expect(opened, isTrue);
  });

  testWidgets('reply card has reactions and no nested reply action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReviewReplyCard(
            reply: _reply(),
            onReactionPressed: (_, _) async => true,
            onDeletePressed: (_) async => true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.thumb_up_alt_outlined), findsOneWidget);
    expect(find.byIcon(Icons.thumb_down_alt_outlined), findsOneWidget);
    expect(find.byIcon(Icons.reply_rounded), findsNothing);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
  });
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
    likeCount: 2,
    dislikeCount: 1,
    currentUserReaction: null,
    isOwnReview: false,
    replyCount: replyCount,
  );
}

ReviewReply _reply() {
  return ReviewReply(
    id: 'reply-1',
    reviewId: 'review-1',
    authorId: 'author-2',
    authorName: 'Reply author',
    authorAvatarUrl: '',
    body: 'Reply body',
    createdAt: DateTime.utc(2026, 8, 2),
    likeCount: 4,
    dislikeCount: 1,
    currentUserReaction: null,
    isOwnReply: false,
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
