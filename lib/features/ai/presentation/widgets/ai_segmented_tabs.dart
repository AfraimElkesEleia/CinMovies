import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/ai/presentation/model/ai_screen_tab.dart';
import 'package:flutter/material.dart';

class AiSegmentedTabs extends StatelessWidget {
  const AiSegmentedTabs({
    super.key,
    required this.activeTab,
    required this.historyCount,
    required this.onChanged,
  });

  final AiScreenTab activeTab;
  final int historyCount;
  final ValueChanged<AiScreenTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _AiSegmentButton(
            label: 'Chat',
            icon: Icons.chat_bubble_outline_rounded,
            isSelected: activeTab == AiScreenTab.chat,
            onTap: () => onChanged(AiScreenTab.chat),
          ),
          _AiSegmentButton(
            label: 'History',
            icon: Icons.history_rounded,
            badge: historyCount,
            isSelected: activeTab == AiScreenTab.history,
            onTap: () => onChanged(AiScreenTab.history),
          ),
        ],
      ),
    );
  }
}

class _AiSegmentButton extends StatelessWidget {
  const _AiSegmentButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF151B2E) : AppColors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.surfaceBorder
                  : AppColors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.white : AppColors.iconMuted,
                size: 16,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.iconMuted,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (badge != null && badge! > 0) ...[
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.loginPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
