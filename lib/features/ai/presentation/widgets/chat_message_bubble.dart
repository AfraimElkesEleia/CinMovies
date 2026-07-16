import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/ai/presentation/data/ai_mock_data.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/ai_logo.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/movie_recommendation_card.dart';
import 'package:flutter/material.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.message});

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment =
        message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final rowAlignment =
        message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start;
    final time = formatMessageTime(TimeOfDay.fromDateTime(message.timestamp));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment: rowAlignment,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                const AiLogo(size: 32),
                const SizedBox(width: 9),
              ],
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 310),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    gradient: message.isUser
                        ? const LinearGradient(
                            colors: [
                              AppColors.loginPrimary,
                              AppColors.loginPrimaryDark,
                            ],
                          )
                        : null,
                    color: message.isUser ? null : AppColors.surface,
                    border: message.isUser
                        ? null
                        : Border.all(color: AppColors.surfaceBorder),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(message.isUser ? 18 : 5),
                      bottomRight: Radius.circular(message.isUser ? 5 : 18),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (message.movies.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 122,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: message.movies.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return MovieRecommendationCard(movie: message.movies[index]);
                },
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 42),
            child: Text(
              time,
              style: const TextStyle(
                color: AppColors.textDisabled,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
