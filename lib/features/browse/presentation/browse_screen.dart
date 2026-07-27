import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/browse/presentation/cubit/browse_cubit.dart';
import 'package:cinmovies_app/features/browse/presentation/widgets/browse_loading_shimmer.dart';
import 'package:cinmovies_app/features/browse/presentation/widgets/browse_screen_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<BrowseCubit>()..loadInitial(),
      child: const _BrowseView(),
    );
  }
}

class _BrowseView extends StatefulWidget {
  const _BrowseView();

  @override
  State<_BrowseView> createState() => _BrowseViewState();
}

class _BrowseViewState extends State<_BrowseView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.extentAfter > 500) return;

    context.read<BrowseCubit>().loadNextPage();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrowseCubit, BrowseState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.loginPrimary,
              backgroundColor: AppColors.surface,
              onRefresh: context.read<BrowseCubit>().refresh,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BrowseHeader(
                            genres: state.genres,
                            selectedGenre: state.selectedGenre,
                            movieCount: state.movies.length,
                            onGenreSelected: context
                                .read<BrowseCubit>()
                                .selectGenre,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
                  if (state.status == BrowseStatus.loading)
                    const BrowseLoadingShimmer()
                  else if (state.movies.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: BrowseEmptyState(),
                    )
                  else
                    BrowseMovieGrid(movies: state.movies),
                  if (state.isLoadingMore)
                    const SliverToBoxAdapter(child: BrowsePaginationLoader()),
                  if (state.failure != null)
                    SliverToBoxAdapter(
                      child: BrowseErrorBanner(message: state.failure!.message),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
