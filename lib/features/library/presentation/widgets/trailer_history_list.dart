import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/movie_image.dart';
import 'package:cinmovies_app/features/trailers/domain/entities/trailer_history_entry.dart';
import 'package:flutter/material.dart';

class TrailerHistoryList extends StatelessWidget {
  const TrailerHistoryList({
    super.key,
    required this.entries,
    required this.emptyLabel,
    required this.onPressed,
  });

  final List<TrailerHistoryEntry> entries;
  final String emptyLabel;
  final ValueChanged<TrailerHistoryEntry> onPressed;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                emptyLabel,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _TrailerHistoryCard(
          entry: entry,
          onPressed: () => onPressed(entry),
        );
      },
    );
  }
}

class _TrailerHistoryCard extends StatelessWidget {
  const _TrailerHistoryCard({
    required this.entry,
    required this.onPressed,
  });

  final TrailerHistoryEntry entry;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final posterWidth = isCompact ? 74.0 : 96.0;
        final posterHeight = posterWidth * 9 / 16;

        return Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              padding: EdgeInsets.all(isCompact ? 10 : 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: posterWidth,
                      height: posterHeight,
                      child: MovieImage(path: entry.imageAsset),
                    ),
                  ),
                  SizedBox(width: isCompact ? 10 : 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_formatDuration(entry.watchedSeconds)} / '
                          '${_formatDuration(entry.totalSeconds)}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Semantics(
                          label: '${entry.percentage}% watched',
                          value: '${entry.percentage}%',
                          excludeSemantics: true,
                          child: Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: entry.progress,
                                    minHeight: isCompact ? 5 : 6,
                                    backgroundColor: AppColors.surfaceBorder,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppColors.loginPrimary,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 42,
                                child: Text(
                                  '${entry.percentage}%',
                                  textAlign: TextAlign.end,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: AppColors.loginPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isCompact ? 4 : 8),
                  const Icon(
                    Icons.play_circle_fill_rounded,
                    color: AppColors.loginPrimary,
                    size: 30,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _formatDuration(int seconds) {
    final safeSeconds = seconds < 0 ? 0 : seconds;
    final hours = safeSeconds ~/ 3600;
    final minutes = (safeSeconds % 3600) ~/ 60;
    final remainingSeconds = safeSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:'
          '${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
