import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/movie_details/presentation/model/movie_details_args.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/movies/presentation/model/movie_list_options.dart';
import 'package:cinmovies_app/features/movies/presentation/widgets/movie_results_list.dart';
import 'package:cinmovies_app/features/movies/presentation/widgets/movie_results_loading_shimmer.dart';
import 'package:cinmovies_app/features/movies/presentation/widgets/movie_search_field.dart';
import 'package:cinmovies_app/features/search/presentation/cubit/search_cubit.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_header.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_suggestions_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<SearchCubit>(),
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
                MovieSearchField(
                  controller: _controller,
                  hasQuery: state.hasQuery,
                  onChanged: _setQuery,
                  onSubmitted: (value) {
                    context.read<SearchCubit>().submitQuery(value);
                  },
                  onClearPressed: () {
                    _controller.clear();
                    context.read<SearchCubit>().clearQuery();
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
                            await context.read<SearchCubit>().submitQuery(value);
                          },
                        )
                      : state.status == MovieListStatus.loading
                      ? const MovieResultsLoadingShimmer()
                      : MovieResultsList(
                          controller: _scrollController,
                          query: state.query,
                          movies: state.results,
                          status: state.status,
                          sortOption: state.sortOption,
                          onSortOptionChanged: context
                              .read<SearchCubit>()
                              .selectSortOption,
                          isLoadingMore: state.isLoadingMore,
                          failureMessage: state.failure?.message,
                          onMoviePressed: (movie, heroTag) {
                            context.read<SearchCubit>().saveCurrentQuery();
                            _openMovie(movie, heroTag);
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

  void _openMovie(Movie movie, String heroTag) {
    context.pushNamed(
      AppRoutes.movieDetails,
      arguments: MovieDetailsArgs(movie: movie, heroTag: heroTag),
    );
  }
}
