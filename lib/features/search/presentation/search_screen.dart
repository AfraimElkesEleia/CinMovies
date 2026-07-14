import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/search/presentation/data/search_mock_data.dart';
import 'package:cinmovies_app/features/search/presentation/utils/search_movie_filter.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_header.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_input_field.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_results_view.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_suggestions_view.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  bool get _hasQuery => _query.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuery(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    setState(() {
      _query = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = SearchMovieFilter.byQuery(
      movies: SearchMockData.movies,
      query: _query,
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            SearchHeader(onBackPressed: () => Navigator.pop(context)),
            SearchInputField(
              controller: _controller,
              hasQuery: _hasQuery,
              onChanged: _setQuery,
              onClearPressed: () => _setQuery(''),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _hasQuery
                  ? SearchResultsView(query: _query, movies: results)
                  : SearchSuggestionsView(onSelected: _setQuery),
            ),
          ],
        ),
      ),
    );
  }
}
