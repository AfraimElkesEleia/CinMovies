import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/ai/domain/entities/movie_chat_models.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/ai_logo.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/movie_recommendation_card.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:flutter/material.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.onMoviePressed,
    required this.onSuggestedReply,
  });

  final MovieChatMessage message;
  final void Function(Movie movie, String heroTag) onMoviePressed;
  final ValueChanged<String> onSuggestedReply;

  @override
  Widget build(BuildContext context) {
    final alignment = message.isUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final rowAlignment = message.isUser
        ? MainAxisAlignment.end
        : MainAxisAlignment.start;
    final time = _formatMessageTime(
      TimeOfDay.fromDateTime(message.createdAt.toLocal()),
    );

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
                    message.content,
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
          if (message.recommendations.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 136,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: message.recommendations.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final recommendation = message.recommendations[index];
                  final heroTag =
                      'ai-recommendation-${message.id}-$index-'
                      '${recommendation.movie.id}';
                  return MovieRecommendationCard(
                    recommendation: recommendation,
                    heroTag: heroTag,
                    onPressed: () =>
                        onMoviePressed(recommendation.movie, heroTag),
                  );
                },
              ),
            ),
          ],
          if (message.suggestedReplies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: message.suggestedReplies.map((reply) {
                return ActionChip(
                  label: Text(reply),
                  onPressed: () => onSuggestedReply(reply),
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.surfaceBorder),
                  labelStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
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

String _formatMessageTime(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}
