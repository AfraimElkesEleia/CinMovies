import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/features/ai/domain/entities/movie_chat_models.dart';

abstract interface class MovieChatRepository {
  bool get isGuest;

  Future<Result<List<MovieChatSession>>> loadSessions();

  Future<Result<List<MovieChatMessage>>> loadMessages(String sessionId);

  Future<Result<MovieChatResponse>> sendMessage({
    required String conversationId,
    required String requestId,
    required MovieChatMessage optimisticMessage,
    required String locale,
    required List<MovieChatMessage> context,
  });

  Future<Result<void>> deleteSession(String sessionId);
}
