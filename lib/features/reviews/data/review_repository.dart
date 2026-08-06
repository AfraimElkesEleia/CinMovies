import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/core/supabase/supabase_database_service.dart';
import 'package:cinmovies_app/features/reviews/data/model/community_review.dart';
import 'package:cinmovies_app/features/reviews/data/model/review_reply.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/movies/data/movie_repository.dart';
import 'package:dartz/dartz.dart';

class ReviewRepository {
  const ReviewRepository(
    this._database,
    this._movieRepository,
  );

  final SupabaseDatabaseService _database;
  final MovieRepository _movieRepository;

  String get _userId {
    final id = _database.currentUser?.id;
    if (id == null) throw StateError('No authenticated user.');
    return id;
  }

  Future<Either<Failure, void>> upsertReview({
    required Movie movie,
    required double rating,
    String? title,
    String? body,
    bool spoiler = false,
  }) async {
    try {
      final movieIdResult = await _movieRepository.cacheMovie(movie);
      return movieIdResult.fold(
        Left.new,
        (movieId) async {
          await _database.from('user_reviews').upsert({
            'user_id': _userId,
            'movie_id': movieId,
            'rating': rating,
            'title': title,
            'body': body,
            'spoiler': spoiler,
          }, onConflict: 'user_id,movie_id');
          return const Right(null);
        },
      );
    } catch (error) {
      return Left(mapError(error));
    }
  }

  Future<Either<Failure, List<CommunityReview>>> reviewsForMovie(
    Movie movie,
  ) async {
    try {
      final movieIdResult = await _movieRepository.cacheMovie(movie);
      return movieIdResult.fold(
        Left.new,
        (movieId) async {
          final rows = await _database
              .from('user_reviews')
              .select(
                '*, profiles!user_reviews_user_id_profiles_fkey'
                '(username, full_name, avatar_url), '
                'movies(*), review_reactions(user_id, reaction)',
              )
              .eq('movie_id', movieId)
              .order('created_at', ascending: false);
          return Right(await _reviewsFromRowsWithCounts(rows));
        },
      );
    } catch (error) {
      return Left(mapError(error));
    }
  }

  Future<Either<Failure, List<CommunityReview>>> reviewsForCurrentUser() async {
    try {
      final rows = await _database
          .from('user_reviews')
          .select(
            '*, profiles!user_reviews_user_id_profiles_fkey'
            '(username, full_name, avatar_url), '
            'movies(*), review_reactions(user_id, reaction)',
          )
          .eq('user_id', _userId)
          .order('created_at', ascending: false);
      return Right(await _reviewsFromRowsWithCounts(rows));
    } catch (error) {
      return Left(mapError(error));
    }
  }

  Future<Either<Failure, int>> countForCurrentUser() async {
    try {
      final rows = await _database
          .from('user_reviews')
          .select('id')
          .eq('user_id', _userId);
      return Right(rows.length);
    } catch (error) {
      return Left(mapError(error));
    }
  }

  Future<Either<Failure, void>> setReaction({
    required String reviewId,
    required ReviewReaction reaction,
  }) async {
    try {
      await _database.from('review_reactions').upsert({
        'review_id': reviewId,
        'user_id': _userId,
        'reaction': reaction.value,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'review_id,user_id');
      return const Right(null);
    } catch (error) {
      return Left(mapError(error));
    }
  }

  Future<Either<Failure, void>> clearReaction(String reviewId) async {
    try {
      await _database
          .from('review_reactions')
          .delete()
          .eq('review_id', reviewId)
          .eq('user_id', _userId);
      return const Right(null);
    } catch (error) {
      return Left(mapError(error));
    }
  }

  Future<Either<Failure, List<ReviewReply>>> repliesForReview(
    String reviewId,
  ) async {
    try {
      final rows = await _database
          .from('review_replies')
          .select(
            '*, profiles!review_replies_user_id_profiles_fkey'
            '(username, full_name, avatar_url), '
            'reply_reactions(user_id, reaction)',
          )
          .eq('review_id', reviewId)
          .order('created_at');
      return Right(
        rows
            .map<Map<String, dynamic>>(Map<String, dynamic>.from)
            .map(
              (row) => ReviewReply.fromRow(
                row,
                currentUserId: _database.currentUser?.id,
              ),
            )
            .toList(),
      );
    } catch (error) {
      return Left(mapError(error));
    }
  }

  Future<Either<Failure, void>> createReply({
    required String reviewId,
    required String body,
  }) async {
    try {
      await _database.from('review_replies').insert({
        'review_id': reviewId,
        'user_id': _userId,
        'body': body.trim(),
      });
      return const Right(null);
    } catch (error) {
      return Left(mapError(error));
    }
  }

  Future<Either<Failure, void>> deleteReply(String replyId) async {
    try {
      await _database
          .from('review_replies')
          .delete()
          .eq('id', replyId)
          .eq('user_id', _userId);
      return const Right(null);
    } catch (error) {
      return Left(mapError(error));
    }
  }

  Future<Either<Failure, void>> setReplyReaction({
    required String replyId,
    required ReviewReaction reaction,
  }) async {
    try {
      await _database.from('reply_reactions').upsert({
        'reply_id': replyId,
        'user_id': _userId,
        'reaction': reaction.value,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'reply_id,user_id');
      return const Right(null);
    } catch (error) {
      return Left(mapError(error));
    }
  }

  Future<Either<Failure, void>> clearReplyReaction(String replyId) async {
    try {
      await _database
          .from('reply_reactions')
          .delete()
          .eq('reply_id', replyId)
          .eq('user_id', _userId);
      return const Right(null);
    } catch (error) {
      return Left(mapError(error));
    }
  }

  Future<Either<Failure, void>> deleteReview(String reviewId) async {
    try {
      await _database
          .from('user_reviews')
          .delete()
          .eq('id', reviewId)
          .eq('user_id', _userId);
      return const Right(null);
    } catch (error) {
      return Left(mapError(error));
    }
  }

  Future<List<CommunityReview>> _reviewsFromRowsWithCounts(
    List<dynamic> rows,
  ) async {
    final normalizedRows = rows
        .map<Map<String, dynamic>>(
          (row) => Map<String, dynamic>.from(row as Map),
        )
        .toList();
    if (normalizedRows.isEmpty) return const [];

    final reviewIds = normalizedRows
        .map((row) => row['id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    final countRows = await _database.rpc(
      'get_review_reply_counts',
      params: {'p_review_ids': reviewIds},
    );
    final counts = <String, int>{};
    if (countRows is List) {
      for (final rawRow in countRows.whereType<Map>()) {
        final row = Map<String, dynamic>.from(rawRow);
        final reviewId = row['review_id'] as String?;
        if (reviewId != null) {
          counts[reviewId] = (row['reply_count'] as num?)?.toInt() ?? 0;
        }
      }
    }

    return normalizedRows
        .map(
          (row) => CommunityReview.fromRow(
            row,
            currentUserId: _database.currentUser?.id,
            replyCount: counts[row['id']] ?? 0,
          ),
        )
        .toList();
  }
}

