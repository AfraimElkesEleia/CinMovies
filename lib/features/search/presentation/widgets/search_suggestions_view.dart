import 'package:cinmovies_app/features/search/presentation/widgets/search_term_list.dart';
import 'package:flutter/material.dart';

class SearchSuggestionsView extends StatelessWidget {
  const SearchSuggestionsView({
    super.key,
    required this.onSelected,
    required this.onDeleted,
    this.recentSearches = const [],
  });

  final ValueChanged<String> onSelected;
  final ValueChanged<String> onDeleted;
  final List<String> recentSearches;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        SearchTermList(
          title: 'Recent Searches',
          terms: recentSearches,
          leadingIcon: Icons.history_rounded,
          onSelected: onSelected,
          onDeleted: onDeleted,
        ),
      ],
    );
  }
}
