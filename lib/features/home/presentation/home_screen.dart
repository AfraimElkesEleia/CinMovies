import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/home_movie_carousel.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/home_loading_shimmer.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/home_section_header.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/home_screen_sections.dart';
import 'package:cinmovies_app/features/movie_details/data/model/movie_details_args.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HomeCubit>()..loadMovies(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    void openDetails(Movie movie, String heroTag) {
      context.pushNamed(
        Routes.movieDetails,
        arguments: MovieDetailsArgs(movie: movie, heroTag: heroTag),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state.status == HomeStatus.loading) {
              return RefreshIndicator(
                color: AppColors.loginPrimary,
                backgroundColor: AppColors.surface,
                onRefresh: context.read<HomeCubit>().loadMovies,
                child: const HomeLoadingShimmer(),
              );
            }

            return RefreshIndicator(
              color: AppColors.loginPrimary,
              backgroundColor: AppColors.surface,
              onRefresh: context.read<HomeCubit>().loadMovies,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: HomeTopBar()),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                  if (state.carouselMovies.isEmpty)
                    const SliverToBoxAdapter(child: HomeEmptyState())
                  else
                    SliverToBoxAdapter(
                      child: HomeMovieCarousel(
                        movies: state.carouselMovies,
                        heroTagFor: (movie, index) =>
                            'home-carousel-$index-${movie.id}',
                        onMoviePressed: openDetails,
                      ),
                    ),
                  if (state.status == HomeStatus.failure &&
                      state.failure != null)
                    SliverToBoxAdapter(
                      child: HomeErrorBanner(message: state.failure!.message),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 26)),
                  SliverToBoxAdapter(
                    child: HomeSectionHeader(
                      title: 'Trending Now',
                      onSeeAllPressed: () {},
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverToBoxAdapter(
                    child: HomeMovieRow(
                      movies: state.popularMovies,
                      heroTagPrefix: 'home-popular',
                      onMoviePressed: openDetails,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(
                    child: HomeSectionHeader(
                      title: 'New Releases',
                      onSeeAllPressed: () {},
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverToBoxAdapter(
                    child: HomeMovieRow(
                      movies: state.upcomingMovies,
                      heroTagPrefix: 'home-upcoming',
                      onMoviePressed: openDetails,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
