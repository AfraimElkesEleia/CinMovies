import 'package:cinmovies_app/features/ai/domain/entities/movie_chat_models.dart';
import 'package:cinmovies_app/features/home/data/tmdb_movie_mapper.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

class MovieChatMessageDto {
  const MovieChatMessageDto(this.value);

  factory MovieChatMessageDto.fromJson(Object? json) {
    final map = _stringMap(json);
    if (map == null) throw const FormatException('Invalid chat message.');

    final id = _requiredUuid(map['id']);
    final role = MovieChatRole.tryParse(map['role']);
    final content = (map['content'] as String?)?.trim();
    final createdAt = DateTime.tryParse(
      (map['createdAt'] ?? map['created_at'])?.toString() ?? '',
    )?.toUtc();
    if (role == null ||
        content == null ||
        content.isEmpty ||
        createdAt == null) {
      throw const FormatException('Invalid chat message fields.');
    }

    return MovieChatMessageDto(
      MovieChatMessage(
        id: id,
        role: role,
        content: content,
        createdAt: createdAt,
        recommendations: _recommendations(map['movies']),
        suggestedReplies: _stringList(
          map['suggestedReplies'] ?? map['suggested_replies'],
          maximum: 4,
        ),
      ),
    );
  }

  factory MovieChatMessageDto.fromDatabaseRow(Object? json) {
    final map = _stringMap(json);
    if (map == null) throw const FormatException('Invalid message row.');
    final relations = map['ai_message_movies'];
    final movies = <Map<String, dynamic>>[];
    if (relations is Iterable) {
      final ordered =
          relations.map(_stringMap).whereType<Map<String, dynamic>>().toList()
            ..sort(
              (a, b) => ((a['rank'] as num?) ?? 0).compareTo(
                (b['rank'] as num?) ?? 0,
              ),
            );
      for (final relation in ordered) {
        final movie = _stringMap(relation['movies']);
        if (movie == null) continue;
        final genreNames = <String>[];
        final movieGenres = movie['movie_genres'];
        if (movieGenres is Iterable) {
          for (final item in movieGenres) {
            final relationMap = _stringMap(item);
            final genre = _stringMap(relationMap?['genres']);
            final name = (genre?['name'] as String?)?.trim();
            if (name != null && name.isNotEmpty) genreNames.add(name);
          }
        }
        movies.add({
          'movie': {...movie, 'id': movie['tmdb_id'], 'genres': genreNames},
          'reason': relation['reason'],
        });
      }
    }
    return MovieChatMessageDto.fromJson({...map, 'movies': movies});
  }

  final MovieChatMessage value;

  Map<String, dynamic> toJson() {
    return {
      'id': value.id,
      'role': value.role.value,
      'content': value.content,
      'created_at': value.createdAt.toUtc().toIso8601String(),
      'suggested_replies': value.suggestedReplies,
      'movies': value.recommendations.map((item) {
        return {'movie': _movieToJson(item.movie), 'reason': item.reason};
      }).toList(),
    };
  }
}

class MovieChatSessionDto {
  const MovieChatSessionDto(this.value, {this.messages = const []});

  factory MovieChatSessionDto.fromJson(Object? json) {
    final map = _stringMap(json);
    if (map == null) throw const FormatException('Invalid chat session.');
    final id = _requiredUuid(map['id']);
    final title = (map['title'] as String?)?.trim();
    final updatedAt = DateTime.tryParse(
      (map['updatedAt'] ?? map['updated_at'])?.toString() ?? '',
    )?.toUtc();
    if (title == null || title.isEmpty || updatedAt == null) {
      throw const FormatException('Invalid chat session fields.');
    }

    final messages = <MovieChatMessage>[];
    final rawMessages = map['messages'] ?? map['ai_chat_messages'];
    if (rawMessages is Iterable) {
      for (final item in rawMessages) {
        try {
          messages.add(MovieChatMessageDto.fromJson(item).value);
        } on FormatException {
          // A damaged local message should not make all guest history unusable.
        }
      }
    }
    final messageCount =
        (map['messageCount'] as num?)?.toInt() ??
        (map['message_count'] as num?)?.toInt() ??
        messages.length;

    return MovieChatSessionDto(
      MovieChatSession(
        id: id,
        title: title,
        preview: (map['preview'] as String?)?.trim() ?? '',
        updatedAt: updatedAt,
        messageCount: messageCount,
      ),
      messages: messages,
    );
  }

  final MovieChatSession value;
  final List<MovieChatMessage> messages;

  Map<String, dynamic> toJson() {
    return {
      'id': value.id,
      'title': value.title,
      'preview': value.preview,
      'updated_at': value.updatedAt.toUtc().toIso8601String(),
      'message_count': messages.length,
      'messages': messages
          .map((message) => MovieChatMessageDto(message).toJson())
          .toList(),
    };
  }
}

List<MovieRecommendation> _recommendations(Object? value) {
  if (value is! Iterable) return const [];
  final recommendations = <MovieRecommendation>[];
  for (final item in value) {
    try {
      final map = _stringMap(item);
      final movieMap = _stringMap(map?['movie']);
      final reason = (map?['reason'] as String?)?.trim();
      if (movieMap == null || reason == null || reason.isEmpty) continue;
      final movie = TmdbMovieMapper.fromJson(movieMap);
      if (movie.id.isEmpty) continue;
      recommendations.add(MovieRecommendation(movie: movie, reason: reason));
    } on Object {
      // Partial responses may contain one malformed movie. Exclude it safely.
    }
  }
  return recommendations;
}

Map<String, dynamic> _movieToJson(Movie movie) {
  return {
    'id': int.tryParse(movie.id),
    'title': movie.title,
    'poster_path': movie.imageAsset,
    'release_date': int.tryParse(movie.year) == null
        ? null
        : '${movie.year}-01-01',
    'runtime': _runtimeMinutes(movie.duration),
    'age_rating': movie.ageRating,
    'vote_average': movie.rating,
    'vote_count': _voteCount(movie.votes),
    'overview': movie.synopsis,
    'genres': movie.genres,
  };
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
  return normalized.endsWith('K') ? (value * 1000).round() : value.round();
}

String _requiredUuid(Object? value) {
  final id = (value as String?)?.trim();
  if (id == null || !_uuidPattern.hasMatch(id)) {
    throw const FormatException('Invalid UUID.');
  }
  return id;
}

Map<String, dynamic>? _stringMap(Object? value) {
  if (value is! Map) return null;
  try {
    return Map<String, dynamic>.from(value);
  } on Object {
    return null;
  }
}

List<String> _stringList(Object? value, {required int maximum}) {
  if (value is! Iterable) return const [];
  return value
      .whereType<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .take(maximum)
      .toList();
}
