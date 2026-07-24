import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/home/data/model/movie_section_args.dart';
import 'package:cinmovies_app/features/home/presentation/cubit/movie_section_cubit.dart';
import 'package:cinmovies_app/features/search/presentation/cubit/search_cubit.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_input_field.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_loading_shimmer.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_results_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MovieSectionScreen extends StatelessWidget {
  const MovieSectionScreen({super.key, required this.args});

  final MovieSectionArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MovieSectionCubit>(param1: args)..loadInitial(),
      child: const _MovieSectionView(),
    );
  }
}

class _MovieSectionView extends StatefulWidget {
  const _MovieSectionView();

  @override
  State<_MovieSectionView> createState() => _MovieSectionViewState();
}

class _MovieSectionViewState extends State<_MovieSectionView> {
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
    context.read<MovieSectionCubit>().loadNextPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: BlocBuilder<MovieSectionCubit, MovieSectionState>(
          builder: (context, state) {
            final cubit = context.read<MovieSectionCubit>();

            return Column(
              children: [
                _MovieSectionHeader(
                  title: state.title,
                  onBackPressed: () => Navigator.pop(context),
                ),
                SearchInputField(
                  controller: _controller,
                  hasQuery: state.hasQuery,
                  onChanged: cubit.setQuery,
                  onClearPressed: () {
                    _controller.clear();
                    cubit.clearQuery();
                  },
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: state.status == SearchStatus.loading
                      ? const SearchLoadingShimmer()
                      : SearchResultsView(
                          controller: _scrollController,
                          query: state.hasQuery
                              ? state.query
                              : state.title,
                          movies: state.visibleMovies,
                          status: state.status,
                          sortMode: state.sortMode,
                          onSortModeChanged: cubit.setSortMode,
                          isLoadingMore: state.isLoadingMore,
                          failureMessage: state.failure?.message,
                          heroTagPrefix: state.heroTagPrefix,
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

class _MovieSectionHeader extends StatelessWidget {
  const _MovieSectionHeader({
    required this.title,
    required this.onBackPressed,
  });

  final String title;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackPressed,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
