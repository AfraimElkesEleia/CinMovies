import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:cinmovies_app/features/home/data/model/movie_section_args.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
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
import 'package:url_launcher/url_launcher.dart';

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
    void openMovieDetails(Movie movie, String heroTag) {
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
                            movies: state.favoriteMovies.take(10).toList(),
                            onMoviePressed: openMovieDetails,
                            onSeeAllPressed: () => _openLibrarySection(
                              context,
                              title: 'Favorites',
                              type: UserMovieListType.favorite,
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        SliverToBoxAdapter(
                          child: ProfileMovieSection(
                            title: 'Watchlist',
                            movies: state.watchlistMovies.take(10).toList(),
                            onMoviePressed: openMovieDetails,
                            onSeeAllPressed: () => _openLibrarySection(
                              context,
                              title: 'Watchlist',
                              type: UserMovieListType.watchlist,
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        SliverToBoxAdapter(
                          child: ProfileAccountSection(
                            onMyReviewsPressed: () {},
                            onFavoriteGenresPressed: () =>
                                _openFavoriteGenres(context),
                            onSupportHelpPressed: () =>
                                _openSupportHelp(context),
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

  void _openLibrarySection(
    BuildContext context, {
    required String title,
    required UserMovieListType type,
  }) {
    context.pushNamed(
      Routes.movieSection,
      arguments: MovieSectionArgs.library(title: title, type: type),
    );
  }

  Future<void> _openSupportHelp(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _SupportHelpDialog(),
    );
  }
}

class _SupportHelpDialog extends StatelessWidget {
  const _SupportHelpDialog();

  static const _email = 'afraimeleia200@gmail.com';

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
        'Support & Help',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact email',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            _email,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openFacebook(context),
                  icon: const Icon(Icons.facebook_rounded, size: 19),
                  label: const Text('Facebook'),
                  style: _buttonStyle(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openGmail(context),
                  icon: const Icon(Icons.mail_outline_rounded, size: 19),
                  label: const Text('Gmail'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.loginPrimary,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  static ButtonStyle _buttonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.loginPrimary,
      side: BorderSide(color: AppColors.loginPrimary.withValues(alpha: 0.55)),
      minimumSize: const Size.fromHeight(46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
    );
  }

  static Future<void> _openFacebook(BuildContext context) async {
    final uri = Uri.https('www.facebook.com', '/search/top/', {'q': _email});
    await _launch(context, uri);
  }

  static Future<void> _openGmail(BuildContext context) async {
    final gmailUri = Uri.https('mail.google.com', '/mail/', {
      'view': 'cm',
      'fs': '1',
      'to': _email,
    });
    if (await launchUrl(gmailUri, mode: LaunchMode.externalApplication)) {
      return;
    }
    if (!context.mounted) return;

    final mailUri = Uri(
      scheme: 'mailto',
      path: _email,
      queryParameters: const {'subject': 'CinMovies support'},
    );
    await _launch(context, mailUri);
  }

  static Future<void> _launch(BuildContext context, Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open this link.')),
    );
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
