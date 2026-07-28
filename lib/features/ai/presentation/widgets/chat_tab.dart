import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/ai/domain/entities/movie_chat_models.dart';
import 'package:cinmovies_app/features/ai/presentation/cubit/ai_chat_cubit.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/chat_input.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/chat_message_bubble.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/empty_chat.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/thinking_bubble.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:flutter/material.dart';

class ChatTab extends StatelessWidget {
  const ChatTab({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.messages,
    required this.status,
    required this.onPromptSelected,
    required this.onSuggestedReply,
    required this.onMoviePressed,
    required this.onSend,
    required this.onRetry,
    this.failureMessage,
  });

  final TextEditingController controller;
  final ScrollController scrollController;
  final List<MovieChatMessage> messages;
  final AiChatStatus status;
  final String? failureMessage;
  final ValueChanged<String> onPromptSelected;
  final ValueChanged<String> onSuggestedReply;
  final void Function(Movie movie, String heroTag) onMoviePressed;
  final VoidCallback onSend;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            children: [
              if (messages.isEmpty &&
                  status != AiChatStatus.switchingConversation)
                EmptyChat(onPromptSelected: onPromptSelected),
              if (status == AiChatStatus.switchingConversation)
                const Padding(
                  padding: EdgeInsets.only(top: 56),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.loginPrimary,
                    ),
                  ),
                ),
              ...messages.map(
                (message) => ChatMessageBubble(
                  message: message,
                  onMoviePressed: onMoviePressed,
                  onSuggestedReply: onSuggestedReply,
                ),
              ),
              if (status == AiChatStatus.sending) const ThinkingBubble(),
              if (failureMessage != null)
                _ChatErrorBanner(
                  message: failureMessage!,
                  showRetry: status == AiChatStatus.sendFailure,
                  onRetry: onRetry,
                ),
            ],
          ),
        ),
        ChatInput(
          controller: controller,
          onSend: onSend,
          enabled:
              status != AiChatStatus.sending &&
              status != AiChatStatus.switchingConversation,
        ),
      ],
    );
  }
}

class _ChatErrorBanner extends StatelessWidget {
  const _ChatErrorBanner({
    required this.message,
    required this.showRetry,
    required this.onRetry,
  });

  final String message;
  final bool showRetry;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.loginPrimary.withValues(alpha: 0.12),
          border: Border.all(
            color: AppColors.loginPrimary.withValues(alpha: 0.55),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.loginPrimary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
            if (showRetry)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
