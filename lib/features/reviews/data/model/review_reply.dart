import 'package:cinmovies_app/features/reviews/data/model/community_review.dart';
import 'package:equatable/equatable.dart';

class ReviewReply extends Equatable {
  const ReviewReply({
    required this.id,
    required this.reviewId,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.body,
    required this.createdAt,
    required this.likeCount,
    required this.dislikeCount,
    required this.currentUserReaction,
    required this.isOwnReply,
  });

  factory ReviewReply.fromRow(
    Map<String, dynamic> row, {
    required String? currentUserId,
  }) {
    final profileRow = _map(row['profiles']);
    final reactions = _list(row['reply_reactions']);
    final authorId = row['user_id'] as String? ?? '';

    return ReviewReply(
      id: row['id'] as String? ?? '',
      reviewId: row['review_id'] as String? ?? '',
      authorId: authorId,
      authorName:
          profileRow['username'] as String? ??
          profileRow['full_name'] as String? ??
          'Movie Explorer',
      authorAvatarUrl:
          profileRow['avatar_url'] as String? ??
          'https://image.tmdb.org/t/p/w185/default-avatar.png',
      body: (row['body'] as String?)?.trim() ?? '',
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? ''),
      likeCount: reactions
          .where((reaction) => reaction['reaction'] == ReviewReaction.like.value)
          .length,
      dislikeCount: reactions
          .where(
            (reaction) => reaction['reaction'] == ReviewReaction.dislike.value,
          )
          .length,
      currentUserReaction: ReviewReaction.fromValue(
        _currentUserReactionValue(reactions, currentUserId),
      ),
      isOwnReply: currentUserId != null && currentUserId == authorId,
    );
  }

  final String id;
  final String reviewId;
  final String authorId;
  final String authorName;
  final String authorAvatarUrl;
  final String body;
  final DateTime? createdAt;
  final int likeCount;
  final int dislikeCount;
  final ReviewReaction? currentUserReaction;
  final bool isOwnReply;

  String get displayDate {
    final value = createdAt;
    if (value == null) return 'Unknown date';
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  ReviewReply copyWith({
    int? likeCount,
    int? dislikeCount,
    ReviewReaction? currentUserReaction,
    bool clearCurrentUserReaction = false,
  }) {
    return ReviewReply(
      id: id,
      reviewId: reviewId,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      body: body,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      currentUserReaction: clearCurrentUserReaction
          ? null
          : currentUserReaction ?? this.currentUserReaction,
      isOwnReply: isOwnReply,
    );
  }

  @override
  List<Object?> get props => [
    id,
    reviewId,
    authorId,
    authorName,
    authorAvatarUrl,
    body,
    createdAt,
    likeCount,
    dislikeCount,
    currentUserReaction,
    isOwnReply,
  ];

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static List<Map<String, dynamic>> _list(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  static Object? _currentUserReactionValue(
    List<Map<String, dynamic>> reactions,
    String? currentUserId,
  ) {
    if (currentUserId == null) return null;
    for (final reaction in reactions) {
      if (reaction['user_id'] == currentUserId) return reaction['reaction'];
    }
    return null;
  }
}
