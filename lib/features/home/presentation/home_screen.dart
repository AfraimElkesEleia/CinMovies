import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/home_movie_carousel.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/home_loading_shimmer.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/home_section_header.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/movie_card.dart';
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
    void openDetails(Object movie) {
      context.pushNamed(Routes.movieDetails, arguments: movie);
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
                  const SliverToBoxAdapter(child: _HomeTopBar()),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                  SliverToBoxAdapter(
                    child: HomeMovieCarousel(
                      movies: state.carouselMovies,
                      onMoviePressed: openDetails,
                    ),
                  ),
                  if (state.status == HomeStatus.failure &&
                      state.failure != null)
                    SliverToBoxAdapter(
                      child: _HomeErrorBanner(message: state.failure!.message),
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
                    child: _HomeMovieRow(
                      movies: state.popularMovies,
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
                    child: _HomeMovieRow(
                      movies: state.upcomingMovies,
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

class _HomeMovieRow extends StatelessWidget {
  const _HomeMovieRow({required this.movies, required this.onMoviePressed});

  final List<HomeMovieModel> movies;
  final ValueChanged<HomeMovieModel> onMoviePressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 206,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final movie = movies[index];
          return MovieCard(movie: movie, onTap: () => onMoviePressed(movie));
        },
      ),
    );
  }
}

class _HomeErrorBanner extends StatelessWidget {
  const _HomeErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
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

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, Afraim',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'What do you want to watch?',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _TopIconButton(
            icon: Icons.notifications_none_rounded,
            onPressed: () {},
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/images/app_logo.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textMuted,
            fixedSize: const Size(40, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: Icon(icon, size: 21),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.loginPrimary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
