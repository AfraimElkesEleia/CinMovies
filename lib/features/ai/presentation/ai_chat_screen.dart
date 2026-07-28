import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/ai/domain/entities/movie_chat_models.dart';
import 'package:cinmovies_app/features/ai/presentation/cubit/ai_chat_cubit.dart';
import 'package:cinmovies_app/features/ai/presentation/model/ai_screen_tab.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/ai_header.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/chat_tab.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/history_tab.dart';
import 'package:cinmovies_app/features/movie_details/presentation/model/movie_details_args.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AiChatScreen extends StatelessWidget {
  const AiChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<AiChatCubit>()..loadHistory(),
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
  bool _shouldAutoScroll = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_trackScrollPosition);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_trackScrollPosition);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? value]) async {
    final text = value ?? _messageController.text;
    _shouldAutoScroll = true;
    final accepted = await context.read<AiChatCubit>().sendMessage(
      text,
      locale: Localizations.localeOf(context).toLanguageTag(),
    );
    if (!mounted) return;
    if (accepted && value == null) _messageController.clear();
  }

  void _trackScrollPosition() {
    if (!_scrollController.hasClients) return;
    _shouldAutoScroll = _scrollController.position.extentAfter < 100;
  }

  void _scrollToBottom({bool force = false}) {
    if (!force && !_shouldAutoScroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  void _openMovie(Movie movie, String heroTag) {
    context.pushNamed(
      AppRoutes.movieDetails,
      arguments: MovieDetailsArgs(movie: movie, heroTag: heroTag),
    );
  }

  Future<bool> _confirmDelete(MovieChatSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete conversation?',
          style: TextStyle(color: AppColors.white),
        ),
        content: Text(
          '"${session.title}" will be permanently removed.',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return false;
    return context.read<AiChatCubit>().deleteSession(session);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AiChatCubit, AiChatState>(
      listenWhen: (previous, current) {
        return previous.messages != current.messages ||
            previous.activeTab != current.activeTab;
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
                            status: state.status,
                            failureMessage: state.failure?.message,
                            onPromptSelected: _sendMessage,
                            onSuggestedReply: _sendMessage,
                            onMoviePressed: _openMovie,
                            onSend: () => _sendMessage(),
                            onRetry: cubit.retryFailed,
                          )
                        : HistoryTab(
                            key: const ValueKey('history'),
                            sessions: state.sessions,
                            isLoading: state.isLoadingHistory,
                            isDeleting: state.isDeleting,
                            failureMessage:
                                state.status == AiChatStatus.historyFailure
                                ? state.failure?.message
                                : null,
                            onRetry: cubit.loadHistory,
                            onStartChat: cubit.showChat,
                            onSessionSelected: cubit.loadSession,
                            onSessionDeleted: _confirmDelete,
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
