import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_section_title.dart';
import 'package:flutter/material.dart';

class SearchTermList extends StatelessWidget {
  const SearchTermList({
    super.key,
    required this.title,
    required this.terms,
    required this.leadingIcon,
    required this.onSelected,
    this.onDeleted,
  });

  final String title;
  final List<String> terms;
  final IconData leadingIcon;
  final ValueChanged<String> onSelected;
  final ValueChanged<String>? onDeleted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchSectionTitle(title: title),
        const SizedBox(height: 8),
        for (final term in terms)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(leadingIcon, color: AppColors.iconMuted, size: 19),
            title: Text(
              term,
              style: const TextStyle(color: AppColors.white, fontSize: 14),
            ),
            trailing: IconButton(
              onPressed: onDeleted == null ? null : () => onDeleted!(term),
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.iconMuted,
                size: 18,
              ),
            ),
            onTap: () => onSelected(term),
          ),
      ],
    );
  }
}
