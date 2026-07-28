import 'package:cinmovies_app/core/local/hive_cache_service.dart';
import 'package:cinmovies_app/features/ai/data/models/movie_chat_dtos.dart';
import 'package:cinmovies_app/features/ai/domain/entities/movie_chat_models.dart';

class MovieChatLocalDataSource {
  const MovieChatLocalDataSource(this._cache);

  final HiveCacheService _cache;

  List<MovieChatSession> loadSessions(String scopeId) {
    return _sessionDtos(scopeId).map((dto) => dto.value).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<MovieChatMessage> loadMessages(String scopeId, String sessionId) {
    for (final dto in _sessionDtos(scopeId)) {
      if (dto.value.id == sessionId) {
        return [...dto.messages]
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }
    }
    return const [];
  }

  Future<void> replaceSessions(
    String scopeId,
    List<MovieChatSession> sessions,
  ) async {
    final cachedMessages = {
      for (final session in _sessionDtos(scopeId))
        session.value.id: session.messages,
    };
    await _save(
      scopeId,
      sessions
          .map(
            (session) => MovieChatSessionDto(
              session,
              messages: cachedMessages[session.id] ?? const [],
            ),
          )
          .toList(),
    );
  }

  Future<void> replaceMessages({
    required String scopeId,
    required String conversationId,
    required List<MovieChatMessage> messages,
  }) async {
    final sessions = _sessionDtos(scopeId);
    final index = sessions.indexWhere(
      (session) => session.value.id == conversationId,
    );
    final replacement = _sessionFromMessages(conversationId, [...messages]);
    if (index < 0) {
      sessions.insert(0, replacement);
    } else {
      sessions[index] = MovieChatSessionDto(
        sessions[index].value,
        messages: replacement.messages,
      );
    }
    await _save(scopeId, sessions);
  }

  Future<void> saveOptimisticMessage({
    required String scopeId,
    required String conversationId,
    required MovieChatMessage message,
  }) async {
    final sessions = _sessionDtos(scopeId);
    final index = sessions.indexWhere(
      (session) => session.value.id == conversationId,
    );
    final currentMessages = index < 0
        ? <MovieChatMessage>[]
        : [...sessions[index].messages];
    _upsertMessage(currentMessages, message);
    final session = _sessionFromMessages(conversationId, currentMessages);
    if (index < 0) {
      sessions.insert(0, session);
    } else {
      sessions[index] = session;
    }
    await _save(scopeId, sessions);
  }

  Future<void> saveResponse(
    String scopeId,
    MovieChatResponse response, {
    String? optimisticMessageId,
  }) async {
    final sessions = _sessionDtos(scopeId);
    final index = sessions.indexWhere(
      (session) => session.value.id == response.conversationId,
    );
    final currentMessages = index < 0
        ? <MovieChatMessage>[]
        : [...sessions[index].messages];
    if (optimisticMessageId != null &&
        optimisticMessageId != response.userMessage.id) {
      currentMessages.removeWhere(
        (message) => message.id == optimisticMessageId,
      );
    }
    _upsertMessage(currentMessages, response.userMessage);
    _upsertMessage(currentMessages, response.assistantMessage);
    final session = _sessionFromMessages(
      response.conversationId,
      currentMessages,
    );
    if (index < 0) {
      sessions.insert(0, session);
    } else {
      sessions[index] = session;
    }
    await _save(scopeId, sessions);
  }

  Future<void> deleteSession(String scopeId, String sessionId) async {
    final sessions = _sessionDtos(
      scopeId,
    ).where((session) => session.value.id != sessionId).toList();
    await _save(scopeId, sessions);
  }

  List<MovieChatSessionDto> _sessionDtos(String scopeId) {
    final result = <MovieChatSessionDto>[];
    for (final row in _cache.getMovieChatSessions(scopeId)) {
      try {
        result.add(MovieChatSessionDto.fromJson(row));
      } on FormatException {
        // Invalid local entries are skipped.
      }
    }
    return result;
  }

  MovieChatSessionDto _sessionFromMessages(
    String conversationId,
    List<MovieChatMessage> messages,
  ) {
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final firstUser = messages.where((message) => message.isUser).firstOrNull;
    final latestAssistant = messages
        .where((message) => !message.isUser)
        .lastOrNull;
    final titleSource = firstUser?.content ?? 'New conversation';
    final title = titleSource.length > 60
        ? '${titleSource.substring(0, 57)}...'
        : titleSource;
    final updatedAt = messages.isEmpty
        ? DateTime.now().toUtc()
        : messages.last.createdAt;
    return MovieChatSessionDto(
      MovieChatSession(
        id: conversationId,
        title: title,
        preview: latestAssistant?.content ?? firstUser?.content ?? '',
        updatedAt: updatedAt,
        messageCount: messages.length,
      ),
      messages: messages,
    );
  }

  void _upsertMessage(
    List<MovieChatMessage> messages,
    MovieChatMessage message,
  ) {
    final index = messages.indexWhere((item) => item.id == message.id);
    if (index < 0) {
      messages.add(message);
    } else {
      messages[index] = message;
    }
  }

  Future<void> _save(
    String scopeId,
    List<MovieChatSessionDto> sessions,
  ) {
    sessions.sort((a, b) => b.value.updatedAt.compareTo(a.value.updatedAt));
    return _cache.cacheMovieChatSessions(
      scopeId,
      sessions.map((session) => session.toJson()).toList(),
    );
  }
}
