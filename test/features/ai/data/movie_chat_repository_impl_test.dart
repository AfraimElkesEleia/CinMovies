import 'package:cinmovies_app/features/ai/data/movie_chat_ai_data_source.dart';
import 'package:cinmovies_app/features/ai/data/movie_chat_local_data_source.dart';
import 'package:cinmovies_app/features/ai/data/movie_chat_remote_data_source.dart';
import 'package:cinmovies_app/features/ai/data/movie_chat_repository_impl.dart';
import 'package:cinmovies_app/features/ai/domain/entities/movie_chat_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('authenticated send persists in Supabase and user-scoped Hive', () async {
    final ai = _FakeAiDataSource();
    final remote = _FakeRemoteDataSource(isGuestValue: false);
    final local = _FakeLocalDataSource();
    final repository = MovieChatRepositoryImpl(ai, remote, local);

    final result = await repository.sendMessage(
      conversationId: _conversationId,
      requestId: _requestId,
      optimisticMessage: _optimisticMessage,
      locale: 'en',
      context: const [],
    );

    expect(result.isRight(), isTrue);
    final response = result.getOrElse(() => throw StateError('Expected data'));
    expect(response.userMessage.id, _persistedUserId);
    expect(response.assistantMessage.id, _persistedAssistantId);
    expect(response.assistantMessage.content, 'A grounded answer.');
    expect(remote.persistCalls, 1);
    expect(local.optimisticScopes, ['user:account-one']);
    expect(local.responseScopes, ['user:account-one']);
  });

  test('guest send never writes to Supabase and uses guest Hive scope', () async {
    final ai = _FakeAiDataSource();
    final remote = _FakeRemoteDataSource(isGuestValue: true);
    final local = _FakeLocalDataSource();
    final repository = MovieChatRepositoryImpl(ai, remote, local);

    final result = await repository.sendMessage(
      conversationId: _conversationId,
      requestId: _requestId,
      optimisticMessage: _optimisticMessage,
      locale: 'en',
      context: const [],
    );

    expect(result.isRight(), isTrue);
    expect(remote.persistCalls, 0);
    expect(local.optimisticScopes, ['guest']);
    expect(local.responseScopes, ['guest']);
  });

  test('authenticated history falls back to the matching local cache', () async {
    final cached = MovieChatSession(
      id: _conversationId,
      title: 'Cached chat',
      preview: 'Available offline',
      updatedAt: DateTime.utc(2026, 7, 28),
      messageCount: 2,
    );
    final remote = _FakeRemoteDataSource(
      isGuestValue: false,
      failLoads: true,
    );
    final local = _FakeLocalDataSource(sessions: [cached]);
    final repository = MovieChatRepositoryImpl(
      _FakeAiDataSource(),
      remote,
      local,
    );

    final result = await repository.loadSessions();

    expect(result.getOrElse(() => const []), [cached]);
    expect(local.loadedScopes, ['user:account-one']);
  });
}

class _FakeAiDataSource implements MovieChatAiDataSource {
  @override
  Future<MovieChatDraft> generate({
    required String message,
    required String locale,
    required List<MovieChatMessage> context,
  }) async {
    return const MovieChatDraft(
      content: 'A grounded answer.',
      recommendations: [],
      suggestedReplies: ['Another one'],
    );
  }
}

class _FakeRemoteDataSource implements MovieChatRemoteDataSource {
  _FakeRemoteDataSource({
    required this.isGuestValue,
    this.failLoads = false,
  });

  final bool isGuestValue;
  final bool failLoads;
  int persistCalls = 0;

  @override
  bool get isGuest => isGuestValue;

  @override
  String get scopeId => isGuest ? 'guest' : 'user:account-one';

  @override
  Future<void> deleteSession(String sessionId) async {}

  @override
  Future<List<MovieChatMessage>> loadMessages(String sessionId) async {
    if (failLoads) throw StateError('offline');
    return const [];
  }

  @override
  Future<List<MovieChatSession>> loadSessions() async {
    if (failLoads) throw StateError('offline');
    return const [];
  }

  @override
  Future<PersistedMovieChatExchange> persistExchange({
    required String conversationId,
    required String requestId,
    required String userContent,
    required MovieChatDraft draft,
  }) async {
    persistCalls++;
    return PersistedMovieChatExchange(
      userMessageId: _persistedUserId,
      userCreatedAt: DateTime.utc(2026, 7, 28, 12),
      assistantMessageId: _persistedAssistantId,
      assistantCreatedAt: DateTime.utc(2026, 7, 28, 12, 0, 1),
    );
  }
}

class _FakeLocalDataSource implements MovieChatLocalDataSource {
  _FakeLocalDataSource({this.sessions = const []});

  final List<MovieChatSession> sessions;
  final List<String> loadedScopes = [];
  final List<String> optimisticScopes = [];
  final List<String> responseScopes = [];

  @override
  Future<void> deleteSession(String scopeId, String sessionId) async {}

  @override
  List<MovieChatMessage> loadMessages(String scopeId, String sessionId) {
    loadedScopes.add(scopeId);
    return const [];
  }

  @override
  List<MovieChatSession> loadSessions(String scopeId) {
    loadedScopes.add(scopeId);
    return sessions;
  }

  @override
  Future<void> replaceMessages({
    required String scopeId,
    required String conversationId,
    required List<MovieChatMessage> messages,
  }) async {}

  @override
  Future<void> replaceSessions(
    String scopeId,
    List<MovieChatSession> sessions,
  ) async {}

  @override
  Future<void> saveOptimisticMessage({
    required String scopeId,
    required String conversationId,
    required MovieChatMessage message,
  }) async {
    optimisticScopes.add(scopeId);
  }

  @override
  Future<void> saveResponse(
    String scopeId,
    MovieChatResponse response, {
    String? optimisticMessageId,
  }) async {
    responseScopes.add(scopeId);
  }
}

const _conversationId = '4c824faa-1ed4-4e9f-acd8-ab38665734bf';
const _requestId = '1e3a38eb-7e6e-4391-8898-3fc14f554a68';
const _persistedUserId = 'c374852b-4d6d-4e30-9e6d-ec2da2fa0770';
const _persistedAssistantId = '7a324a71-e660-43d0-a2e6-b6f31437ecab';
final _optimisticMessage = MovieChatMessage(
  id: _requestId,
  role: MovieChatRole.user,
  content: 'Recommend a movie',
  createdAt: DateTime.utc(2026, 7, 28, 12),
);
