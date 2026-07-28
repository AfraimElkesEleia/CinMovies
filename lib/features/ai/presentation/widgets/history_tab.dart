import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/ai/domain/entities/movie_chat_models.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/history_tile.dart';
import 'package:flutter/material.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({
    super.key,
    required this.sessions,
    required this.onStartChat,
    required this.onSessionSelected,
    required this.onSessionDeleted,
    required this.isLoading,
    required this.isDeleting,
    required this.onRetry,
    this.failureMessage,
  });

  final List<MovieChatSession> sessions;
  final VoidCallback onStartChat;
  final ValueChanged<MovieChatSession> onSessionSelected;
  final Future<bool> Function(MovieChatSession) onSessionDeleted;
  final bool isLoading;
  final bool isDeleting;
  final String? failureMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.loginPrimary),
      );
    }

    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: AppColors.iconMuted,
                  size: 30,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'No Chat History',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your conversations will appear here.',
                style: TextStyle(color: AppColors.iconMuted, fontSize: 13),
              ),
              const SizedBox(height: 18),
              if (failureMessage != null) ...[
                Text(
                  failureMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.loginPrimary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
                const SizedBox(height: 6),
              ],
              ElevatedButton(
                onPressed: onStartChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.loginPrimary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Start a Chat'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: sessions.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            '${sessions.length} conversations',
            style: const TextStyle(
              color: AppColors.iconMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          );
        }

        final session = sessions[index - 1];
        return HistoryTile(
          session: session,
          enabled: !isDeleting,
          onTap: () => onSessionSelected(session),
          onDelete: () => onSessionDeleted(session),
        );
      },
    );
  }
}
