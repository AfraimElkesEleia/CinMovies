import 'package:cinmovies_app/core/supabase/supabase_database_service.dart';
import 'package:cinmovies_app/features/ai/data/models/movie_chat_dtos.dart';
import 'package:cinmovies_app/features/ai/data/movie_chat_ai_data_source.dart';
import 'package:cinmovies_app/features/ai/domain/entities/movie_chat_models.dart';

class MovieChatRemoteDataSource {
  const MovieChatRemoteDataSource(this._database);

  final SupabaseDatabaseService _database;

  bool get isGuest {
    final user = _database.currentUser;
    return user == null || user.isAnonymous;
  }

  String get scopeId {
    final user = _database.currentUser;
    return user == null || user.isAnonymous ? 'guest' : 'user:${user.id}';
  }

  Future<List<MovieChatSession>> loadSessions() async {
    final userId = _requiredAccountId;
    final rows = await _database
        .from('ai_chat_sessions')
        .select('id,title,preview,updated_at,ai_chat_messages(id)')
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    final sessions = <MovieChatSession>[];
    for (final row in rows) {
      try {
        final map = Map<String, dynamic>.from(row);
        final messages = map['ai_chat_messages'];
        map['message_count'] = messages is Iterable ? messages.length : 0;
        sessions.add(MovieChatSessionDto.fromJson(map).value);
      } on FormatException {
        // Keep valid conversations when one database row is damaged.
      }
    }
    return sessions;
  }

  Future<List<MovieChatMessage>> loadMessages(String sessionId) async {
    final userId = _requiredAccountId;
    final rows = await _database
        .from('ai_chat_messages')
        .select(
          'id,role,content,created_at,suggested_replies,'
          'ai_message_movies(reason,rank,movies('
          'tmdb_id,title,original_title,overview,poster_path,backdrop_path,'
          'release_date,runtime_minutes,age_rating,vote_average,vote_count,'
          'movie_genres(genres(name))))',
        )
        .eq('session_id', sessionId)
        .eq('user_id', userId)
        .order('created_at');

    final messages = <MovieChatMessage>[];
    for (final row in rows) {
      try {
        messages.add(MovieChatMessageDto.fromDatabaseRow(row).value);
      } on FormatException {
        // Ignore one invalid message rather than lose the whole conversation.
      }
    }
    return messages;
  }

  Future<PersistedMovieChatExchange> persistExchange({
    required String conversationId,
    required String requestId,
    required String userContent,
    required MovieChatDraft draft,
  }) async {
    _requiredAccountId;
    final result = await _database.rpc(
      'persist_movie_chat_exchange',
      params: {
        'p_session_id': conversationId,
        'p_request_id': requestId,
        'p_user_content': userContent,
        'p_assistant_content': draft.content,
        'p_suggested_replies': draft.suggestedReplies,
        'p_movies': draft.recommendations
            .map(_recommendationPersistenceJson)
            .toList(),
      },
    );
    return PersistedMovieChatExchange.fromJson(result);
  }

  Future<void> deleteSession(String sessionId) async {
    final userId = _requiredAccountId;
    await _database
        .from('ai_chat_sessions')
        .delete()
        .eq('id', sessionId)
        .eq('user_id', userId);
  }

  String get _requiredAccountId {
    final user = _database.currentUser;
    if (user == null || user.isAnonymous) {
      throw StateError('An authenticated account is required.');
    }
    return user.id;
  }

  Map<String, dynamic> _recommendationPersistenceJson(
    MovieRecommendation recommendation,
  ) {
    final movie = recommendation.movie;
    return {
      'tmdbId': int.tryParse(movie.id),
      'title': movie.title,
      'originalTitle': movie.title,
      'overview': movie.synopsis,
      'posterPath': movie.imageAsset,
      'backdropPath': movie.imageAsset,
      'releaseDate': _releaseDate(movie.year),
      'runtime': _runtimeMinutes(movie.duration),
      'ageRating': movie.ageRating == 'NR' ? null : movie.ageRating,
      'voteAverage': movie.rating,
      'voteCount': _voteCount(movie.votes),
      'popularity': null,
      'genres': movie.genres,
      'reason': recommendation.reason,
    };
  }

  String? _releaseDate(String year) {
    final value = int.tryParse(year);
    return value == null ? null : '$value-01-01';
  }

  int? _runtimeMinutes(String duration) {
    final hours = RegExp(r'(\d+)h').firstMatch(duration);
    final minutes = RegExp(r'(\d+)m').firstMatch(duration);
    final result =
        (int.tryParse(hours?.group(1) ?? '') ?? 0) * 60 +
        (int.tryParse(minutes?.group(1) ?? '') ?? 0);
    return result > 0 ? result : null;
  }

  int? _voteCount(String votes) {
    final normalized = votes.trim().toUpperCase();
    final value = double.tryParse(normalized.replaceAll('K', ''));
    if (value == null) return null;
    return normalized.endsWith('K')
        ? (value * 1000).round()
        : value.round();
  }
}

class PersistedMovieChatExchange {
  const PersistedMovieChatExchange({
    required this.userMessageId,
    required this.userCreatedAt,
    required this.assistantMessageId,
    required this.assistantCreatedAt,
  });

  factory PersistedMovieChatExchange.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('Invalid saved chat.');
    final map = Map<String, dynamic>.from(value);
    final userMessageId = _requiredText(map['userMessageId']);
    final assistantMessageId = _requiredText(map['assistantMessageId']);
    final userCreatedAt = DateTime.tryParse(
      map['userCreatedAt']?.toString() ?? '',
    )?.toUtc();
    final assistantCreatedAt = DateTime.tryParse(
      map['assistantCreatedAt']?.toString() ?? '',
    )?.toUtc();
    if (userCreatedAt == null || assistantCreatedAt == null) {
      throw const FormatException('Invalid saved chat timestamps.');
    }
    return PersistedMovieChatExchange(
      userMessageId: userMessageId,
      userCreatedAt: userCreatedAt,
      assistantMessageId: assistantMessageId,
      assistantCreatedAt: assistantCreatedAt,
    );
  }

  final String userMessageId;
  final DateTime userCreatedAt;
  final String assistantMessageId;
  final DateTime assistantCreatedAt;

  static String _requiredText(Object? value) {
    final text = value is String ? value.trim() : '';
    if (text.isEmpty) throw const FormatException('Invalid saved chat ID.');
    return text;
  }
}
