import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:equatable/equatable.dart';

enum MovieChatRole {
  user('user'),
  assistant('assistant');

  const MovieChatRole(this.value);

  final String value;

  static MovieChatRole? tryParse(Object? value) {
    for (final role in values) {
      if (role.value == value) return role;
    }
    return null;
  }
}

class MovieRecommendation extends Equatable {
  const MovieRecommendation({required this.movie, required this.reason});

  final Movie movie;
  final String reason;

  @override
  List<Object> get props => [movie, reason];
}

class MovieChatMessage extends Equatable {
  const MovieChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.recommendations = const [],
    this.suggestedReplies = const [],
  });

  final String id;
  final MovieChatRole role;
  final String content;
  final DateTime createdAt;
  final List<MovieRecommendation> recommendations;
  final List<String> suggestedReplies;

  bool get isUser => role == MovieChatRole.user;

  @override
  List<Object> get props => [
    id,
    role,
    content,
    createdAt,
    recommendations,
    suggestedReplies,
  ];
}

class MovieChatSession extends Equatable {
  const MovieChatSession({
    required this.id,
    required this.title,
    required this.preview,
    required this.updatedAt,
    required this.messageCount,
  });

  final String id;
  final String title;
  final String preview;
  final DateTime updatedAt;
  final int messageCount;

  @override
  List<Object> get props => [id, title, preview, updatedAt, messageCount];
}

class MovieChatResponse extends Equatable {
  const MovieChatResponse({
    required this.conversationId,
    required this.userMessage,
    required this.assistantMessage,
  });

  final String conversationId;
  final MovieChatMessage userMessage;
  final MovieChatMessage assistantMessage;

  @override
  List<Object> get props => [conversationId, userMessage, assistantMessage];
}
