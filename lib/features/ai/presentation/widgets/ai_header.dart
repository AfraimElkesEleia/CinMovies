import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/ai/presentation/model/ai_screen_tab.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/ai_logo.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/ai_segmented_tabs.dart';
import 'package:flutter/material.dart';

class AiHeader extends StatelessWidget {
  const AiHeader({
    super.key,
    required this.activeTab,
    required this.historyCount,
    required this.canStartNewChat,
    required this.onTabChanged,
    required this.onNewChat,
  });

  final AiScreenTab activeTab;
  final int historyCount;
  final bool canStartNewChat;
  final ValueChanged<AiScreenTab> onTabChanged;
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Column(
        children: [
          Row(
            children: [
              const AiLogo(size: 42),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CinMovies AI',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Row(
                      children: [
                        OnlineDot(),
                        SizedBox(width: 6),
                        Text(
                          'Online',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: canStartNewChat
                    ? TextButton.icon(
                        key: const ValueKey('new-chat'),
                        onPressed: onNewChat,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                          backgroundColor: AppColors.surface,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(
                              color: AppColors.surfaceBorder,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 17),
                        label: const Text(
                          'New Chat',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AiSegmentedTabs(
            activeTab: activeTab,
            historyCount: historyCount,
            onChanged: onTabChanged,
          ),
        ],
      ),
    );
  }
}
