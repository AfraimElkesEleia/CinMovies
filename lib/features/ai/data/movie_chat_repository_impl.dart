import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/features/ai/data/movie_chat_ai_data_source.dart';
import 'package:cinmovies_app/features/ai/data/movie_chat_local_data_source.dart';
import 'package:cinmovies_app/features/ai/data/movie_chat_remote_data_source.dart';
import 'package:cinmovies_app/features/ai/domain/entities/movie_chat_models.dart';
import 'package:cinmovies_app/features/ai/domain/repositories/movie_chat_repository.dart';
import 'package:uuid/uuid.dart';

class MovieChatRepositoryImpl implements MovieChatRepository {
  MovieChatRepositoryImpl(
    this._ai,
    this._remote,
    this._local,
    this._errorMapper, [
    Uuid? uuid,
  ]) : _uuid = uuid ?? const Uuid();

  final MovieChatAiDataSource _ai;
  final MovieChatRemoteDataSource _remote;
  final MovieChatLocalDataSource _local;
  final ErrorMapper _errorMapper;
  final Uuid _uuid;

  @override
  bool get isGuest => _remote.isGuest;

  @override
  Future<Result<List<MovieChatSession>>> loadSessions() async {
    final scopeId = _remote.scopeId;
    if (isGuest) return Success(_local.loadSessions(scopeId));

    try {
      final sessions = await _remote.loadSessions();
      await _local.replaceSessions(scopeId, sessions);
      return Success(sessions);
    } catch (error) {
      final cached = _local.loadSessions(scopeId);
      return cached.isNotEmpty
          ? Success(cached)
          : _errorMapper.toFailure(error);
    }
  }

  @override
  Future<Result<List<MovieChatMessage>>> loadMessages(String sessionId) async {
    final scopeId = _remote.scopeId;
    if (isGuest) return Success(_local.loadMessages(scopeId, sessionId));

    try {
      final messages = await _remote.loadMessages(sessionId);
      await _local.replaceMessages(
        scopeId: scopeId,
        conversationId: sessionId,
        messages: messages,
      );
      return Success(messages);
    } catch (error) {
      final cached = _local.loadMessages(scopeId, sessionId);
      return cached.isNotEmpty
          ? Success(cached)
          : _errorMapper.toFailure(error);
    }
  }

  @override
  Future<Result<MovieChatResponse>> sendMessage({
    required String conversationId,
    required String requestId,
    required MovieChatMessage optimisticMessage,
    required String locale,
    required List<MovieChatMessage> context,
  }) async {
    final scopeId = _remote.scopeId;
    try {
      await _local.saveOptimisticMessage(
        scopeId: scopeId,
        conversationId: conversationId,
        message: optimisticMessage,
      );
      final draft = await _ai.generate(
        message: optimisticMessage.content,
        locale: locale,
        context: context,
      );
      final now = DateTime.now().toUtc();
      var userMessageId = optimisticMessage.id;
      var userCreatedAt = optimisticMessage.createdAt;
      var assistantMessageId = _uuid.v4();
      var assistantCreatedAt = now;

      if (!isGuest) {
        final saved = await _remote.persistExchange(
          conversationId: conversationId,
          requestId: requestId,
          userContent: optimisticMessage.content,
          draft: draft,
        );
        userMessageId = saved.userMessageId;
        userCreatedAt = saved.userCreatedAt;
        assistantMessageId = saved.assistantMessageId;
        assistantCreatedAt = saved.assistantCreatedAt;
      }

      final response = MovieChatResponse(
        conversationId: conversationId,
        userMessage: MovieChatMessage(
          id: userMessageId,
          role: MovieChatRole.user,
          content: optimisticMessage.content,
          createdAt: userCreatedAt,
        ),
        assistantMessage: MovieChatMessage(
          id: assistantMessageId,
          role: MovieChatRole.assistant,
          content: draft.content,
          createdAt: assistantCreatedAt,
          recommendations: draft.recommendations,
          suggestedReplies: draft.suggestedReplies,
        ),
      );
      try {
        await _local.saveResponse(
          scopeId,
          response,
          optimisticMessageId: optimisticMessage.id,
        );
      } catch (_) {
        if (isGuest) rethrow;
        // The Supabase transaction already succeeded. Return the answer and
        // let the next history refresh rebuild this account's local cache.
      }
      return Success(response);
    } catch (error) {
      return _errorMapper.toFailure(error);
    }
  }

  @override
  Future<Result<void>> deleteSession(String sessionId) async {
    final scopeId = _remote.scopeId;
    try {
      if (!isGuest) await _remote.deleteSession(sessionId);
      await _local.deleteSession(scopeId, sessionId);
      return const Success(null);
    } catch (error) {
      return _errorMapper.toFailure(error);
    }
  }
}
