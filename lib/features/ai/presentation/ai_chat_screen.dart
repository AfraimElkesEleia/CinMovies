import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/ai/presentation/data/ai_mock_data.dart';
import 'package:cinmovies_app/features/ai/presentation/model/ai_screen_tab.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/ai_header.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/chat_tab.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/history_tab.dart';
import 'package:flutter/material.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  AiScreenTab _activeTab = AiScreenTab.chat;
  List<AiChatMessage> _messages = [];
  late List<AiChatSession> _sessions;
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    _sessions = AiMockData.initialSessions();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? value]) async {
    final text = (value ?? _messageController.text).trim();
    if (text.isEmpty || _isThinking) return;

    _messageController.clear();
    setState(() {
      _messages = [..._messages, _userMessage(text)];
      _isThinking = true;
      _activeTab = AiScreenTab.chat;
    });

    _scrollToBottom();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final response = AiMockData.responseFor(text);
    setState(() {
      _messages = [..._messages, _aiMessage(response)];
      _isThinking = false;
    });
    _scrollToBottom();
  }

  void _startNewChat() {
    setState(() {
      if (_messages.isNotEmpty) {
        _sessions = [_sessionFromMessages(_messages), ..._sessions];
      }

      _messages = [];
      _isThinking = false;
      _activeTab = AiScreenTab.chat;
    });
  }

  void _loadSession(AiChatSession session) {
    setState(() {
      _messages = session.messages;
      _isThinking = false;
      _activeTab = AiScreenTab.chat;
    });
    _scrollToBottom();
  }

  void _deleteSession(AiChatSession session) {
    setState(() {
      _sessions = _sessions
          .where((savedSession) => savedSession.id != session.id)
          .toList();
    });
  }

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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            AiHeader(
              activeTab: _activeTab,
              historyCount: _sessions.length,
              canStartNewChat: _canStartNewChat,
              onTabChanged: (tab) => setState(() => _activeTab = tab),
              onNewChat: _startNewChat,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _activeTab == AiScreenTab.chat
                    ? ChatTab(
                        key: const ValueKey('chat'),
                        controller: _messageController,
                        scrollController: _scrollController,
                        messages: _messages,
                        isThinking: _isThinking,
                        onPromptSelected: _sendMessage,
                        onSend: () => _sendMessage(),
                      )
                    : HistoryTab(
                        key: const ValueKey('history'),
                        sessions: _sessions,
                        onStartChat: _showChat,
                        onSessionSelected: _loadSession,
                        onSessionDeleted: _deleteSession,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canStartNewChat {
    return _activeTab == AiScreenTab.chat && _messages.isNotEmpty && !_isThinking;
  }

  void _showChat() {
    setState(() => _activeTab = AiScreenTab.chat);
  }
}
