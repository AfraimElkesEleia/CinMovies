import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/search/presentation/cubit/search_cubit.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_header.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_input_field.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_loading_shimmer.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_results_view.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_suggestions_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SearchCubit>(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter > 420) return;
    context.read<SearchCubit>().loadNextPage();
  }

  void _setQuery(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    context.read<SearchCubit>().setQuery(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: BlocBuilder<SearchCubit, SearchState>(
          builder: (context, state) {
            return Column(
              children: [
                SearchHeader(onBackPressed: () => Navigator.pop(context)),
                SearchInputField(
                  controller: _controller,
                  hasQuery: state.hasQuery,
                  onChanged: _setQuery,
                  onSubmitted: (value) {
                    context.read<SearchCubit>().submit(value);
                  },
                  onClearPressed: () {
                    _controller.clear();
                    context.read<SearchCubit>().clear();
                  },
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: !state.hasQuery
                      ? SearchSuggestionsView(
                          recentSearches: state.recentSearches,
                          onDeleted: (value) {
                            context.read<SearchCubit>().deleteRecentSearch(
                              value,
                            );
                          },
                          onSelected: (value) async {
                            _setQuery(value);
                            await context.read<SearchCubit>().submit(value);
                          },
                        )
                      : state.status == SearchStatus.loading
                      ? const SearchLoadingShimmer()
                      : SearchResultsView(
                          controller: _scrollController,
                          query: state.query,
                          movies: state.results,
                          status: state.status,
                          isLoadingMore: state.isLoadingMore,
                          failureMessage: state.failure?.message,
                          onMoviePressed: (_) {
                            context.read<SearchCubit>().saveCurrentQuery();
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
