import 'package:cinmovies_app/features/ai/presentation/data/ai_mock_data.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/chat_input.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/chat_message_bubble.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/empty_chat.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/thinking_bubble.dart';
import 'package:flutter/material.dart';

class ChatTab extends StatelessWidget {
  const ChatTab({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.messages,
    required this.isThinking,
    required this.onPromptSelected,
    required this.onSend,
  });

  final TextEditingController controller;
  final ScrollController scrollController;
  final List<AiChatMessage> messages;
  final bool isThinking;
  final ValueChanged<String> onPromptSelected;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            children: [
              if (messages.isEmpty) EmptyChat(onPromptSelected: onPromptSelected),
              ...messages.map((message) => ChatMessageBubble(message: message)),
              if (isThinking) const ThinkingBubble(),
            ],
          ),
        ),
        ChatInput(controller: controller, onSend: onSend),
      ],
    );
  }
}
