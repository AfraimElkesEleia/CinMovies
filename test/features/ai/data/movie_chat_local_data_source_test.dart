import 'dart:io';

import 'package:cinmovies_app/core/local/hive_cache_service.dart';
import 'package:cinmovies_app/features/ai/data/movie_chat_local_data_source.dart';
import 'package:cinmovies_app/features/ai/domain/entities/movie_chat_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDirectory;
  late HiveCacheService cache;
  late MovieChatLocalDataSource dataSource;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('movie_chat_cache_');
    Hive.init(tempDirectory.path);
    cache = HiveCacheService(
      await Hive.openBox<dynamic>('search'),
      await Hive.openBox<dynamic>('movies'),
      await Hive.openBox<dynamic>('users'),
      await Hive.openBox<dynamic>('genres'),
      movieChatBox: await Hive.openBox<dynamic>('movie_chat'),
    );
    dataSource = MovieChatLocalDataSource(cache);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('keeps complete conversations isolated by cache scope', () async {
    final response = MovieChatResponse(
      conversationId: _conversationId,
      userMessage: _userMessage,
      assistantMessage: _assistantMessage,
    );

    await dataSource.saveResponse('guest', response);

    expect(dataSource.loadSessions('guest'), hasLength(1));
    expect(dataSource.loadMessages('guest', _conversationId), [
      _userMessage,
      _assistantMessage,
    ]);
    expect(dataSource.loadSessions('user:account-user-id'), isEmpty);
    expect(cache.getMovieChatSessions('guest'), hasLength(1));
    expect(cache.getMovieChatSessions('user:account-user-id'), isEmpty);
  });

  test('replaces an optimistic ID with the persisted user message ID', () async {
    const optimisticId = '1e3a38eb-7e6e-4391-8898-3fc14f554a68';
    await dataSource.saveOptimisticMessage(
      scopeId: 'user:one',
      conversationId: _conversationId,
      message: _userMessage,
    );
    final persistedUser = MovieChatMessage(
      id: 'e65de461-8270-449d-9984-18c45aecfcd8',
      role: MovieChatRole.user,
      content: _userMessage.content,
      createdAt: _userMessage.createdAt,
    );

    await dataSource.saveResponse(
      'user:one',
      MovieChatResponse(
        conversationId: _conversationId,
        userMessage: persistedUser,
        assistantMessage: _assistantMessage,
      ),
      optimisticMessageId: optimisticId,
    );

    final messages = dataSource.loadMessages('user:one', _conversationId);
    expect(messages.map((message) => message.id), [
      persistedUser.id,
      _assistantMessage.id,
    ]);
  });
}

const _conversationId = '4c824faa-1ed4-4e9f-acd8-ab38665734bf';
final _userMessage = MovieChatMessage(
  id: '1e3a38eb-7e6e-4391-8898-3fc14f554a68',
  role: MovieChatRole.user,
  content: 'Recommend a comedy',
  createdAt: DateTime.utc(2026, 7, 28, 12),
);
final _assistantMessage = MovieChatMessage(
  id: '7a324a71-e660-43d0-a2e6-b6f31437ecab',
  role: MovieChatRole.assistant,
  content: 'Here is a grounded answer.',
  createdAt: DateTime.utc(2026, 7, 28, 12, 0, 1),
  suggestedReplies: const ['Something newer'],
);
