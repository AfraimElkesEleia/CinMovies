import 'package:cinmovies_app/core/constants/api_constants.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:equatable/equatable.dart';

enum ReviewReaction {
  like('like'),
  dislike('dislike');

  const ReviewReaction(this.value);

  final String value;

  static ReviewReaction? fromValue(Object? value) {
    return switch (value) {
      'like' => ReviewReaction.like,
      'dislike' => ReviewReaction.dislike,
      _ => null,
    };
  }
}

class CommunityReview extends Equatable {
  const CommunityReview({
    required this.id,
    required this.movie,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.rating,
    required this.title,
    required this.body,
    required this.spoiler,
    required this.createdAt,
    required this.likeCount,
    required this.dislikeCount,
    required this.currentUserReaction,
    required this.isOwnReview,
  });

  factory CommunityReview.fromRow(
    Map<String, dynamic> row, {
    required String? currentUserId,
  }) {
    final movieRow = _map(row['movies']);
    final profileRow = _map(row['profiles']);
    final reactions = _list(row['review_reactions']);
    final authorId = row['user_id'] as String? ?? '';
    final authorName =
        profileRow['username'] as String? ??
        profileRow['full_name'] as String? ??
        'Movie Explorer';
    final createdAt = DateTime.tryParse(row['created_at'] as String? ?? '');

    return CommunityReview(
      id: row['id'] as String? ?? '',
      movie: _movieFromRow(movieRow),
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl:
          profileRow['avatar_url'] as String? ??
          'https://image.tmdb.org/t/p/w185/default-avatar.png',
      rating: ((row['rating'] as num?) ?? 0).toDouble(),
      title: (row['title'] as String?)?.trim(),
      body: (row['body'] as String?)?.trim() ?? '',
      spoiler: row['spoiler'] as bool? ?? false,
      createdAt: createdAt,
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
      isOwnReview: currentUserId != null && currentUserId == authorId,
    );
  }

  final String id;
  final Movie movie;
  final String authorId;
  final String authorName;
  final String authorAvatarUrl;
  final double rating;
  final String? title;
  final String body;
  final bool spoiler;
  final DateTime? createdAt;
  final int likeCount;
  final int dislikeCount;
  final ReviewReaction? currentUserReaction;
  final bool isOwnReview;

  String get displayDate {
    final value = createdAt;
    if (value == null) return 'Unknown date';
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  String get displayText {
    if (body.isNotEmpty) return body;
    return title?.isNotEmpty == true ? title! : 'No written review.';
  }

  CommunityReview copyWith({
    int? likeCount,
    int? dislikeCount,
    ReviewReaction? currentUserReaction,
    bool clearCurrentUserReaction = false,
  }) {
    return CommunityReview(
      id: id,
      movie: movie,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      rating: rating,
      title: title,
      body: body,
      spoiler: spoiler,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      currentUserReaction: clearCurrentUserReaction
          ? null
          : currentUserReaction ?? this.currentUserReaction,
      isOwnReview: isOwnReview,
    );
  }

  @override
  List<Object?> get props => [
    id,
    movie,
    authorId,
    authorName,
    authorAvatarUrl,
    rating,
    title,
    body,
    spoiler,
    createdAt,
    likeCount,
    dislikeCount,
    currentUserReaction,
    isOwnReview,
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
      if (reaction['user_id'] == currentUserId) {
        return reaction['reaction'];
      }
    }
    return null;
  }

  static Movie _movieFromRow(Map<String, dynamic> row) {
    final releaseDate = row['release_date'] as String?;
    final runtimeMinutes = row['runtime_minutes'] as int?;
    final voteCount = row['vote_count'] as int?;

    return Movie(
      id:
          (row['tmdb_id'] as num?)?.toInt().toString() ??
          (row['id'] as String? ?? ''),
      title:
          (row['title'] as String?) ??
          (row['original_title'] as String?) ??
          'Untitled Movie',
      imageAsset: _imageUrl(
        (row['poster_path'] as String?) ?? (row['backdrop_path'] as String?),
      ),
      genres: const [],
      rating: ((row['vote_average'] as num?) ?? 0).toDouble(),
      year: _yearFromDate(releaseDate),
      duration: _duration(runtimeMinutes),
      ageRating: row['age_rating'] as String? ?? 'NR',
      synopsis: (row['overview'] as String?)?.trim().isNotEmpty == true
          ? (row['overview'] as String).trim()
          : 'No synopsis available.',
      director: 'Unknown',
      votes: _formatVotes(voteCount),
      cast: const [],
      reviews: const [],
    );
  }

  static String _imageUrl(String? path) {
    if (path == null || path.trim().isEmpty) {
      return 'assets/images/app_logo.png';
    }
    if (path.startsWith('http') || path.startsWith('assets/')) return path;
    return '${ApiConstants.imageBaseUrl}$path';
  }

  static String _yearFromDate(String? value) {
    if (value == null || value.length < 4) return 'N/A';
    return value.substring(0, 4);
  }

  static String _duration(int? minutes) {
    if (minutes == null || minutes <= 0) return 'N/A';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) return '${remainingMinutes}m';
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}m';
  }

  static String _formatVotes(int? value) {
    if (value == null) return '0';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }
}
