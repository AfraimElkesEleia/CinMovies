import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_section_title.dart';
import 'package:flutter/material.dart';

class SearchTermChips extends StatelessWidget {
  const SearchTermChips({
    super.key,
    required this.title,
    required this.terms,
    required this.onSelected,
  });

  final String title;
  final List<String> terms;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchSectionTitle(title: title),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: terms.map((term) {
            return ActionChip(
              label: Text(term),
              onPressed: () => onSelected(term),
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.surfaceBorder),
              labelStyle: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
