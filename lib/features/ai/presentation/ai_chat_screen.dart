import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/ai/presentation/cubit/ai_chat_cubit.dart';
import 'package:cinmovies_app/features/ai/presentation/model/ai_screen_tab.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/ai_header.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/chat_tab.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/history_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AiChatScreen extends StatelessWidget {
  const AiChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AiChatCubit(),
      child: const _AiChatView(),
    );
  }
}

class _AiChatView extends StatefulWidget {
  const _AiChatView();

  @override
  State<_AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends State<_AiChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? value]) async {
    final text = value ?? _messageController.text;
    _messageController.clear();
    await context.read<AiChatCubit>().sendMessage(text);
    _scrollToBottom();
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
    return BlocConsumer<AiChatCubit, AiChatState>(
      listenWhen: (previous, current) {
        return previous.messages.length != current.messages.length;
      },
      listener: (context, state) => _scrollToBottom(),
      builder: (context, state) {
        final cubit = context.read<AiChatCubit>();

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: SafeArea(
            child: Column(
              children: [
                AiHeader(
                  activeTab: state.activeTab,
                  historyCount: state.sessions.length,
                  canStartNewChat: state.canStartNewChat,
                  onTabChanged: cubit.setTab,
                  onNewChat: cubit.startNewChat,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: state.activeTab == AiScreenTab.chat
                        ? ChatTab(
                            key: const ValueKey('chat'),
                            controller: _messageController,
                            scrollController: _scrollController,
                            messages: state.messages,
                            isThinking: state.isThinking,
                            onPromptSelected: _sendMessage,
                            onSend: () => _sendMessage(),
                          )
                        : HistoryTab(
                            key: const ValueKey('history'),
                            sessions: state.sessions,
                            onStartChat: cubit.showChat,
                            onSessionSelected: cubit.loadSession,
                            onSessionDeleted: cubit.deleteSession,
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
