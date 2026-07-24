import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:cinmovies_app/features/home/presentation/data/home_mock_data.dart';
import 'package:cinmovies_app/features/home/data/model/home_movie_model.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';
import 'package:cinmovies_app/features/movie_details/data/model/movie_details_args.dart';
import 'package:cinmovies_app/features/profile/data/profile_repository.dart';
import 'package:cinmovies_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:cinmovies_app/features/profile/presentation/widgets/profile_account_section.dart';
import 'package:cinmovies_app/features/profile/presentation/widgets/profile_header.dart';
import 'package:cinmovies_app/features/profile/presentation/widgets/profile_loading_shimmer.dart';
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

    void openMovieDetails(HomeMovieModel movie, String heroTag) {
      context.pushNamed(
        Routes.movieDetails,
        arguments: MovieDetailsArgs(movie: movie, heroTag: heroTag),
      );
    }

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: SafeArea(
            child: state.status == ProfileStatus.loading
                ? const ProfileLoadingShimmer()
                : RefreshIndicator(
                    color: AppColors.loginPrimary,
                    backgroundColor: AppColors.surface,
                    onRefresh: () => context.read<ProfileCubit>().load(),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: ProfileHeader(
                            fullName: state.fullName,
                            bio: state.bio,
                            email: state.email,
                            avatarUrl: state.avatarUrl,
                            onEditPressed: () => _openEditProfile(context),
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
                            onFavoriteGenresPressed: () =>
                                _openFavoriteGenres(context),
                            onSupportHelpPressed: () {},
                            onLogoutPressed: () => _logout(context),
                          ),
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

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _LogoutConfirmationDialog(),
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<ProfileCubit>().logout();
    if (!context.mounted) return;
    context.pushNamedAndRemoveUntil(Routes.login);
  }

  Future<void> _openEditProfile(BuildContext context) async {
    final updated = await context.pushNamed(Routes.editProfile);
    if (!context.mounted || updated != true) return;
    await context.read<ProfileCubit>().load();
  }

  Future<void> _openFavoriteGenres(BuildContext context) async {
    final updated = await context.pushNamed(Routes.favoriteGenres);
    if (!context.mounted || updated != true) return;
    await context.read<ProfileCubit>().load();
  }
}

class _LogoutConfirmationDialog extends StatelessWidget {
  const _LogoutConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.surfaceBorder),
      ),
      title: const Text(
        'Logout?',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: const Text(
        'Are you sure you want to log out of your account?',
        style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.4),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.loginPrimary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Logout'),
        ),
      ],
    );
  }
}
