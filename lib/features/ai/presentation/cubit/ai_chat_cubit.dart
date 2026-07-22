import 'package:cinmovies_app/features/ai/presentation/data/ai_mock_data.dart';
import 'package:cinmovies_app/features/ai/presentation/model/ai_screen_tab.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AiChatState extends Equatable {
  const AiChatState({
    this.activeTab = AiScreenTab.chat,
    this.messages = const [],
    this.sessions = const [],
    this.isThinking = false,
  });

  final AiScreenTab activeTab;
  final List<AiChatMessage> messages;
  final List<AiChatSession> sessions;
  final bool isThinking;

  bool get canStartNewChat {
    return activeTab == AiScreenTab.chat && messages.isNotEmpty && !isThinking;
  }

  AiChatState copyWith({
    AiScreenTab? activeTab,
    List<AiChatMessage>? messages,
    List<AiChatSession>? sessions,
    bool? isThinking,
  }) {
    return AiChatState(
      activeTab: activeTab ?? this.activeTab,
      messages: messages ?? this.messages,
      sessions: sessions ?? this.sessions,
      isThinking: isThinking ?? this.isThinking,
    );
  }

  @override
  List<Object> get props => [activeTab, messages, sessions, isThinking];
}

class AiChatCubit extends Cubit<AiChatState> {
  AiChatCubit()
      : super(AiChatState(sessions: AiMockData.initialSessions()));

  Future<void> sendMessage(String value) async {
    final text = value.trim();
    if (text.isEmpty || state.isThinking) return;

    emit(
      state.copyWith(
        messages: [...state.messages, _userMessage(text)],
        isThinking: true,
        activeTab: AiScreenTab.chat,
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 900));
    final response = AiMockData.responseFor(text);
    emit(
      state.copyWith(
        messages: [...state.messages, _aiMessage(response)],
        isThinking: false,
      ),
    );
  }

  void startNewChat() {
    final sessions = state.messages.isEmpty
        ? state.sessions
        : [_sessionFromMessages(state.messages), ...state.sessions];

    emit(
      state.copyWith(
        sessions: sessions,
        messages: const [],
        isThinking: false,
        activeTab: AiScreenTab.chat,
      ),
    );
  }

  void loadSession(AiChatSession session) {
    emit(
      state.copyWith(
        messages: session.messages,
        isThinking: false,
        activeTab: AiScreenTab.chat,
      ),
    );
  }

  void deleteSession(AiChatSession session) {
    emit(
      state.copyWith(
        sessions: state.sessions
            .where((savedSession) => savedSession.id != session.id)
            .toList(),
      ),
    );
  }

  void showChat() => emit(state.copyWith(activeTab: AiScreenTab.chat));

  void setTab(AiScreenTab tab) => emit(state.copyWith(activeTab: tab));

  AiChatMessage _userMessage(String text) {
    return AiChatMessage(
      id: 'u${DateTime.now().microsecondsSinceEpoch}',
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  AiChatMessage _aiMessage(({List<AiMovie> movies, String text}) response) {
    return AiChatMessage(
      id: 'a${DateTime.now().microsecondsSinceEpoch}',
      text: response.text,
      isUser: false,
      timestamp: DateTime.now(),
      movies: response.movies,
    );
  }

  AiChatSession _sessionFromMessages(List<AiChatMessage> messages) {
    final firstMessage = messages.first.text;
    final aiPreview = messages
        .where((message) => !message.isUser)
        .map((message) => message.text)
        .firstOrNull;

    return AiChatSession(
      id: 's${DateTime.now().microsecondsSinceEpoch}',
      title: firstMessage.length > 30
          ? '${firstMessage.substring(0, 30)}...'
          : firstMessage,
      preview: aiPreview ?? 'New AI conversation',
      timestamp: DateTime.now(),
      messages: messages,
    );
  }
}
