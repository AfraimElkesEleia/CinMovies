import 'dart:async';

import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/features/ai/domain/entities/movie_chat_models.dart';
import 'package:cinmovies_app/features/ai/domain/repositories/movie_chat_repository.dart';
import 'package:cinmovies_app/features/ai/presentation/cubit/ai_chat_cubit.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects an empty message without calling the repository', () async {
    final repository = _FakeMovieChatRepository();
    final cubit = AiChatCubit(repository);
    addTearDown(cubit.close);

    final accepted = await cubit.sendMessage('   ', locale: 'en');

    expect(accepted, isFalse);
    expect(cubit.state.status, AiChatStatus.sendFailure);
    expect(cubit.state.failure?.message, 'Enter a movie question first.');
    expect(repository.sendCount, 0);
  });

  test(
    'optimistically inserts a valid message and completes with answer',
    () async {
      final pending = Completer<Either<Failure, MovieChatResponse>>();
      final repository = _FakeMovieChatRepository(
        sendHandler: (_, _, _) => pending.future,
      );
      final cubit = AiChatCubit(repository);
      addTearDown(cubit.close);

      final send = cubit.sendMessage('A short sci-fi movie', locale: 'en');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, AiChatStatus.sending);
      expect(cubit.state.messages.single.content, 'A short sci-fi movie');
      expect(cubit.state.messages.single.isUser, isTrue);

      final optimistic = cubit.state.messages.single;
      pending.complete(
        Right(_response(cubit.state.conversationId, optimistic)),
      );
      expect(await send, isTrue);
      expect(cubit.state.status, AiChatStatus.ready);
      expect(cubit.state.messages.map((message) => message.role), [
        MovieChatRole.user,
        MovieChatRole.assistant,
      ]);
      expect(cubit.state.messages.last.content, 'Try this grounded pick.');
    },
  );

  test('preserves failed message and retry succeeds', () async {
    final repository = _FakeMovieChatRepository(
      sendHandler: (call, conversationId, optimisticMessage) async {
        if (call == 1) {
          return const Left(NetworkFailure(message: 'No connection'));
        }
        return Right(_response(conversationId, optimisticMessage));
      },
    );
    final cubit = AiChatCubit(repository);
    addTearDown(cubit.close);

    await cubit.sendMessage('Compare these movies', locale: 'en');

    expect(cubit.state.status, AiChatStatus.sendFailure);
    expect(cubit.state.messages.single.content, 'Compare these movies');
    expect(cubit.state.pendingSend, isNotNull);

    await cubit.retryFailed();

    expect(repository.sendCount, 2);
    expect(cubit.state.status, AiChatStatus.ready);
    expect(cubit.state.messages.length, 2);
  });

  test('prevents a duplicate send while a request is pending', () async {
    final pending = Completer<Either<Failure, MovieChatResponse>>();
    final repository = _FakeMovieChatRepository(
      sendHandler: (_, _, _) => pending.future,
    );
    final cubit = AiChatCubit(repository);
    addTearDown(cubit.close);

    final first = cubit.sendMessage('First', locale: 'en');
    await Future<void>.delayed(Duration.zero);
    final second = await cubit.sendMessage('Second', locale: 'en');

    expect(second, isFalse);
    expect(repository.sendCount, 1);
    final optimistic = cubit.state.messages.single;
    pending.complete(Right(_response(cubit.state.conversationId, optimistic)));
    await first;
  });

  test('replaces the optimistic user ID with the persisted database ID', () async {
    final repository = _FakeMovieChatRepository(
      sendHandler: (_, conversationId, optimistic) async {
        final persisted = MovieChatMessage(
          id: 'c374852b-4d6d-4e30-9e6d-ec2da2fa0770',
          role: MovieChatRole.user,
          content: optimistic.content,
          createdAt: optimistic.createdAt,
        );
        return Right(_response(conversationId, persisted));
      },
    );
    final cubit = AiChatCubit(repository);
    addTearDown(cubit.close);

    await cubit.sendMessage('Recommend a classic', locale: 'en');

    expect(cubit.state.messages, hasLength(2));
    expect(
      cubit.state.messages.first.id,
      'c374852b-4d6d-4e30-9e6d-ec2da2fa0770',
    );
  });

  test('switches conversations and loads their messages', () async {
    final message = MovieChatMessage(
      id: '4a2e69aa-1e30-4be2-8df9-ebfc07aeb0dc',
      role: MovieChatRole.assistant,
      content: 'Previous answer',
      createdAt: DateTime.utc(2026),
    );
    final repository = _FakeMovieChatRepository(messages: [message]);
    final cubit = AiChatCubit(repository);
    addTearDown(cubit.close);
    final session = MovieChatSession(
      id: '81f1fd43-2f67-467b-8b5a-4302cfc8024e',
      title: 'Previous chat',
      preview: 'Previous answer',
      updatedAt: DateTime.utc(2026),
      messageCount: 1,
    );

    await cubit.loadSession(session);

    expect(cubit.state.conversationId, session.id);
    expect(cubit.state.status, AiChatStatus.ready);
    expect(cubit.state.messages, [message]);
    expect(repository.loadedSessionId, session.id);
  });
}

MovieChatResponse _response(
  String conversationId,
  MovieChatMessage userMessage,
) {
  return MovieChatResponse(
    conversationId: conversationId,
    userMessage: userMessage,
    assistantMessage: MovieChatMessage(
      id: '835e17d0-55b2-4a7c-ab84-cebcd10c9daa',
      role: MovieChatRole.assistant,
      content: 'Try this grounded pick.',
      createdAt: userMessage.createdAt.add(const Duration(seconds: 1)),
    ),
  );
}

class _FakeMovieChatRepository implements MovieChatRepository {
  _FakeMovieChatRepository({this.sendHandler, this.messages = const []});

  final Future<Either<Failure, MovieChatResponse>> Function(
    int call,
    String conversationId,
    MovieChatMessage optimisticMessage,
  )?
  sendHandler;
  final List<MovieChatMessage> messages;
  int sendCount = 0;
  String? loadedSessionId;

  @override
  bool get isGuest => false;

  @override
  Future<Either<Failure, List<MovieChatSession>>> loadSessions() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<MovieChatMessage>>> loadMessages(
    String sessionId,
  ) async {
    loadedSessionId = sessionId;
    return Right(messages);
  }

  @override
  Future<Either<Failure, MovieChatResponse>> sendMessage({
    required String conversationId,
    required String requestId,
    required MovieChatMessage optimisticMessage,
    required String locale,
    required List<MovieChatMessage> context,
  }) {
    sendCount += 1;
    final handler = sendHandler;
    if (handler == null) {
      throw StateError('Unexpected send');
    }
    return handler(sendCount, conversationId, optimisticMessage);
  }

  @override
  Future<Either<Failure, void>> deleteSession(String sessionId) async {
    return const Right(null);
  }
}
