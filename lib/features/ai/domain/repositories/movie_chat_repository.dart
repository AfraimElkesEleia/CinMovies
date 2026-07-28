import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/features/ai/domain/entities/movie_chat_models.dart';
import 'package:dartz/dartz.dart';

abstract interface class MovieChatRepository {
  bool get isGuest;

  Future<Either<Failure, List<MovieChatSession>>> loadSessions();

  Future<Either<Failure, List<MovieChatMessage>>> loadMessages(
    String sessionId,
  );

  Future<Either<Failure, MovieChatResponse>> sendMessage({
    required String conversationId,
    required String requestId,
    required MovieChatMessage optimisticMessage,
    required String locale,
    required List<MovieChatMessage> context,
  });

  Future<Either<Failure, void>> deleteSession(String sessionId);
}
