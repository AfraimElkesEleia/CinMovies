import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/search/presentation/model/search_category_model.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_section_title.dart';
import 'package:flutter/material.dart';

class SearchCategoryGrid extends StatelessWidget {
  const SearchCategoryGrid({
    super.key,
    required this.categories,
    required this.onSelected,
  });

  final List<SearchCategoryModel> categories;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SearchSectionTitle(title: 'Browse by Category'),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.4,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onSelected(category.label),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.12),
                  border: Border.all(
                    color: category.color.withValues(alpha: 0.25),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(category.icon, color: category.color, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      category.label,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
