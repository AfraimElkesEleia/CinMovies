import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:cinmovies_app/features/home/presentation/data/home_mock_data.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';
import 'package:cinmovies_app/features/profile/data/profile_repository.dart';
import 'package:cinmovies_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:cinmovies_app/features/profile/presentation/widgets/profile_account_section.dart';
import 'package:cinmovies_app/features/profile/presentation/widgets/profile_header.dart';
import 'package:cinmovies_app/features/profile/presentation/widgets/profile_movie_section.dart';
import 'package:cinmovies_app/features/profile/presentation/widgets/profile_stats_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit(
        sl<ProfileRepository>(),
        sl<LibraryRepository>(),
        sl<AuthRepository>(),
      )..load(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final favoriteMovies = kHomeMovies.take(2).toList();
    final watchlistMovies = kHomeMovies.skip(2).take(2).toList();

    void openMovieDetails(HomeMovieModel movie) {
      context.pushNamed(Routes.movieDetails, arguments: movie);
    }

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: ProfileHeader(
                    fullName: state.fullName,
                    subtitle: state.username == null
                        ? 'Movie Explorer'
                        : '@${state.username}',
                    avatarUrl: state.avatarUrl,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: ProfileStatsRow(
                    watchedCount: state.watchedCount,
                    watchlistCount: state.watchlistCount,
                    reviewCount: state.reviewCount,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(
                  child: ProfileMovieSection(
                    title: 'Favorites',
                    movies: favoriteMovies,
                    onMoviePressed: openMovieDetails,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(
                  child: ProfileMovieSection(
                    title: 'Watchlist',
                    movies: watchlistMovies,
                    onMoviePressed: openMovieDetails,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(
                  child: ProfileAccountSection(
                    onMyReviewsPressed: () {},
                    onFavoriteGenresPressed: () {},
                    onSupportHelpPressed: () {},
                    onLogoutPressed: () => _logout(context),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<ProfileCubit>().logout();
    if (!context.mounted) return;
    context.pushNamedAndRemoveUntil(Routes.login);
  }
}
