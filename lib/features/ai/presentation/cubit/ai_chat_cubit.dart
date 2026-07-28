import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/features/ai/domain/entities/movie_chat_models.dart';
import 'package:cinmovies_app/features/ai/domain/repositories/movie_chat_repository.dart';
import 'package:cinmovies_app/features/ai/presentation/model/ai_screen_tab.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

enum AiChatStatus {
  initial,
  loadingHistory,
  ready,
  sending,
  sendFailure,
  historyFailure,
  switchingConversation,
  deletingSession,
}

class PendingMovieChatSend extends Equatable {
  const PendingMovieChatSend({
    required this.requestId,
    required this.conversationId,
    required this.message,
    required this.locale,
    required this.context,
  });

  final String requestId;
  final String conversationId;
  final MovieChatMessage message;
  final String locale;
  final List<MovieChatMessage> context;

  @override
  List<Object> get props => [
    requestId,
    conversationId,
    message,
    locale,
    context,
  ];
}

class AiChatState extends Equatable {
  const AiChatState({
    required this.conversationId,
    required this.isGuest,
    this.status = AiChatStatus.initial,
    this.activeTab = AiScreenTab.chat,
    this.messages = const [],
    this.sessions = const [],
    this.failure,
    this.pendingSend,
  });

  final String conversationId;
  final bool isGuest;
  final AiChatStatus status;
  final AiScreenTab activeTab;
  final List<MovieChatMessage> messages;
  final List<MovieChatSession> sessions;
  final Failure? failure;
  final PendingMovieChatSend? pendingSend;

  bool get isSending => status == AiChatStatus.sending;
  bool get isLoadingHistory => status == AiChatStatus.loadingHistory;
  bool get isSwitching => status == AiChatStatus.switchingConversation;
  bool get isDeleting => status == AiChatStatus.deletingSession;
  bool get canStartNewChat => messages.isNotEmpty && !isSending;

  AiChatState copyWith({
    String? conversationId,
    AiChatStatus? status,
    AiScreenTab? activeTab,
    List<MovieChatMessage>? messages,
    List<MovieChatSession>? sessions,
    Failure? failure,
    PendingMovieChatSend? pendingSend,
    bool clearFailure = false,
    bool clearPendingSend = false,
  }) {
    return AiChatState(
      conversationId: conversationId ?? this.conversationId,
      isGuest: isGuest,
      status: status ?? this.status,
      activeTab: activeTab ?? this.activeTab,
      messages: messages ?? this.messages,
      sessions: sessions ?? this.sessions,
      failure: clearFailure ? null : failure ?? this.failure,
      pendingSend: clearPendingSend ? null : pendingSend ?? this.pendingSend,
    );
  }

  @override
  List<Object?> get props => [
    conversationId,
    isGuest,
    status,
    activeTab,
    messages,
    sessions,
    failure,
    pendingSend,
  ];
}

class AiChatCubit extends Cubit<AiChatState> {
  AiChatCubit(this._repository, {Uuid? uuid})
    : _uuid = uuid ?? Uuid(),
      super(
        AiChatState(
          conversationId: (uuid ?? Uuid()).v4(),
          isGuest: _repository.isGuest,
        ),
      );

  static const maximumMessageLength = 1000;

  final MovieChatRepository _repository;
  final Uuid _uuid;

  Future<void> loadHistory() async {
    if (state.isSending) return;
    emit(
      state.copyWith(status: AiChatStatus.loadingHistory, clearFailure: true),
    );
    final result = await _repository.loadSessions();
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(status: AiChatStatus.historyFailure, failure: failure),
      ),
      (sessions) => emit(
        state.copyWith(
          status: AiChatStatus.ready,
          sessions: sessions,
          clearFailure: true,
        ),
      ),
    );
  }

  Future<bool> sendMessage(String value, {required String locale}) async {
    final text = value.trim();
    if (state.isSending) return false;
    if (text.isEmpty) {
      emit(
        state.copyWith(
          status: AiChatStatus.sendFailure,
          failure: const Failure(
            message: 'Enter a movie question first.',
          ),
          clearPendingSend: true,
        ),
      );
      return false;
    }
    if (text.length > maximumMessageLength) {
      emit(
        state.copyWith(
          status: AiChatStatus.sendFailure,
          failure: const Failure(
            message: 'Keep your message under 1,000 characters.',
          ),
          clearPendingSend: true,
        ),
      );
      return false;
    }

    final context = [...state.messages];
    final requestId = _uuid.v4();
    final optimisticMessage = MovieChatMessage(
      id: requestId,
      role: MovieChatRole.user,
      content: text,
      createdAt: DateTime.now().toUtc(),
    );
    final pending = PendingMovieChatSend(
      requestId: requestId,
      conversationId: state.conversationId,
      message: optimisticMessage,
      locale: locale,
      context: context,
    );
    emit(
      state.copyWith(
        status: AiChatStatus.sending,
        activeTab: AiScreenTab.chat,
        messages: [...context, optimisticMessage],
        pendingSend: pending,
        clearFailure: true,
      ),
    );
    await _performSend(pending);
    return true;
  }

  Future<void> retryFailed() async {
    final pending = state.pendingSend;
    if (pending == null || state.isSending) return;
    emit(state.copyWith(status: AiChatStatus.sending, clearFailure: true));
    await _performSend(pending);
  }

  Future<void> _performSend(PendingMovieChatSend pending) async {
    final result = await _repository.sendMessage(
      conversationId: pending.conversationId,
      requestId: pending.requestId,
      optimisticMessage: pending.message,
      locale: pending.locale,
      context: pending.context,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AiChatStatus.sendFailure,
          failure: failure,
          pendingSend: pending,
        ),
      ),
      (response) {
        final messages = [...state.messages];
        final userIndex = messages.indexWhere(
          (message) =>
              message.id == pending.message.id ||
              message.id == response.userMessage.id,
        );
        if (userIndex < 0) {
          messages.add(response.userMessage);
        } else {
          messages[userIndex] = response.userMessage;
        }
        if (!messages.any(
          (message) => message.id == response.assistantMessage.id,
        )) {
          messages.add(response.assistantMessage);
        }
        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        emit(
          state.copyWith(
            conversationId: response.conversationId,
            status: AiChatStatus.ready,
            messages: messages,
            sessions: _upsertCurrentSession(response.conversationId, messages),
            clearFailure: true,
            clearPendingSend: true,
          ),
        );
      },
    );
  }

  Future<void> loadSession(MovieChatSession session) async {
    if (state.isSending || state.isDeleting) return;
    emit(
      state.copyWith(
        conversationId: session.id,
        status: AiChatStatus.switchingConversation,
        activeTab: AiScreenTab.chat,
        messages: const [],
        clearFailure: true,
        clearPendingSend: true,
      ),
    );
    final result = await _repository.loadMessages(session.id);
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(status: AiChatStatus.historyFailure, failure: failure),
      ),
      (messages) => emit(
        state.copyWith(
          status: AiChatStatus.ready,
          messages: messages,
          clearFailure: true,
        ),
      ),
    );
  }

  Future<bool> deleteSession(MovieChatSession session) async {
    if (state.isSending || state.isDeleting) return false;
    emit(
      state.copyWith(status: AiChatStatus.deletingSession, clearFailure: true),
    );
    final result = await _repository.deleteSession(session.id);
    if (isClosed) return false;
    return result.fold(
      (failure) {
        emit(
          state.copyWith(status: AiChatStatus.historyFailure, failure: failure),
        );
        return false;
      },
      (_) {
        final wasActive = session.id == state.conversationId;
        emit(
          state.copyWith(
            conversationId: wasActive ? _uuid.v4() : state.conversationId,
            status: AiChatStatus.ready,
            sessions: state.sessions
                .where((item) => item.id != session.id)
                .toList(),
            messages: wasActive ? const [] : state.messages,
            clearFailure: true,
            clearPendingSend: true,
          ),
        );
        return true;
      },
    );
  }

  void startNewChat() {
    if (state.isSending) return;
    emit(
      state.copyWith(
        conversationId: _uuid.v4(),
        status: AiChatStatus.ready,
        activeTab: AiScreenTab.chat,
        messages: const [],
        clearFailure: true,
        clearPendingSend: true,
      ),
    );
  }

  void showChat() => setTab(AiScreenTab.chat);

  void setTab(AiScreenTab tab) {
    if (state.isSending && tab == AiScreenTab.history) return;
    emit(state.copyWith(activeTab: tab));
  }

  List<MovieChatSession> _upsertCurrentSession(
    String conversationId,
    List<MovieChatMessage> messages,
  ) {
    final firstUser = messages.where((message) => message.isUser).firstOrNull;
    final latestAssistant = messages
        .where((message) => !message.isUser)
        .lastOrNull;
    final titleSource = firstUser?.content ?? 'New conversation';
    final title = titleSource.length > 60
        ? '${titleSource.substring(0, 57)}...'
        : titleSource;
    final session = MovieChatSession(
      id: conversationId,
      title: title,
      preview: latestAssistant?.content ?? titleSource,
      updatedAt: messages.last.createdAt,
      messageCount: messages.length,
    );
    return [
      session,
      ...state.sessions.where((item) => item.id != conversationId),
    ];
  }
}
