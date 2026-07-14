import 'package:cinmovies_app/features/search/presentation/data/search_mock_data.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_category_grid.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_term_chips.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_term_list.dart';
import 'package:flutter/material.dart';

class SearchSuggestionsView extends StatelessWidget {
  const SearchSuggestionsView({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        SearchTermList(
          title: 'Recent Searches',
          terms: SearchMockData.recentSearches,
          leadingIcon: Icons.history_rounded,
          onSelected: onSelected,
        ),
        const SizedBox(height: 24),
        SearchTermChips(
          title: 'Popular Searches',
          terms: SearchMockData.popularSearches,
          onSelected: onSelected,
        ),
        const SizedBox(height: 24),
        SearchCategoryGrid(
          categories: SearchMockData.categories,
          onSelected: onSelected,
        ),
      ],
    );
  }
}
