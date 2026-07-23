import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/core/widgets/app_shimmer.dart';
import 'package:cinmovies_app/features/browse/data/browse_genre.dart';
import 'package:cinmovies_app/features/browse/presentation/cubit/browse_cubit.dart';
import 'package:cinmovies_app/features/browse/presentation/widgets/browse_loading_shimmer.dart';
import 'package:cinmovies_app/features/browse/presentation/widgets/browse_search_bar.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/movie_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BrowseCubit>()..loadInitial(),
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
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Browse Movies',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        BrowseSearchBar(
                          onTap: () => context.pushNamed(Routes.search),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: state.genres.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final genre = state.genres[index];
                              final isActive = genre == state.activeGenre;

                              return _GenreChip(
                                genre: genre,
                                isActive: isActive,
                                onSelected: () =>
                                    context.read<BrowseCubit>().setGenre(genre),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Text(
                              '${state.movies.length} movies',
                              style: const TextStyle(
                                color: AppColors.iconMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.sort_rounded,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Popularity',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
                    child: _BrowseEmptyState(),
                  )
                else
                  _BrowseMovieGrid(movies: state.movies),
                if (state.isLoadingMore)
                  const SliverToBoxAdapter(child: _BottomLoader()),
                if (state.failure != null)
                  SliverToBoxAdapter(
                    child: _BrowseErrorBanner(message: state.failure!.message),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BrowseMovieGrid extends StatelessWidget {
  const _BrowseMovieGrid({required this.movies});

  final List<HomeMovieModel> movies;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid.builder(
        itemCount: movies.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (context, index) {
          final movie = movies[index];
          return MovieCard(
            movie: movie,
            onTap: () {
              context.pushNamed(
                Routes.movieDetails,
                arguments: movie,
              );
            },
          );
        },
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.genre,
    required this.isActive,
    required this.onSelected,
  });

  final BrowseGenre genre;
  final bool isActive;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(genre.name),
      selected: isActive,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: AppColors.loginPrimary,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: isActive ? AppColors.loginPrimary : AppColors.surfaceBorder,
      ),
      labelStyle: TextStyle(
        color: isActive ? AppColors.white : AppColors.textMuted,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _BottomLoader extends StatelessWidget {
  const _BottomLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: AppShimmer(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppShimmerBox(width: 70, height: 10, radius: 5),
            SizedBox(width: 8),
            AppShimmerBox(width: 34, height: 10, radius: 5),
          ],
        ),
      ),
    );
  }
}

class _BrowseEmptyState extends StatelessWidget {
  const _BrowseEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_filter_outlined,
            color: AppColors.textMuted,
            size: 38,
          ),
          SizedBox(height: 12),
          Text(
            'No movies found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowseErrorBanner extends StatelessWidget {
  const _BrowseErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.loginPrimary.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.loginPrimary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
