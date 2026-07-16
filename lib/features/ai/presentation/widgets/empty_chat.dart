import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/ai/presentation/data/ai_mock_data.dart';
import 'package:cinmovies_app/features/ai/presentation/widgets/ai_logo.dart';
import 'package:flutter/material.dart';

class EmptyChat extends StatelessWidget {
  const EmptyChat({super.key, required this.onPromptSelected});

  final ValueChanged<String> onPromptSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 18),
      child: Column(
        children: [
          const AiLogo(size: 64),
          const SizedBox(height: 16),
          const Text(
            'Ask for a movie match',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell me your mood, genre, time limit, or who you are watching with.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.iconMuted,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: AiMockData.suggestedPrompts.map((prompt) {
              return ActionChip(
                label: Text(prompt),
                onPressed: () => onPromptSelected(prompt),
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.surfaceBorder),
                labelStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
