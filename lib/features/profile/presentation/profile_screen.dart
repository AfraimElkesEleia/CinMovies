import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/home/presentation/data/home_mock_data.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:cinmovies_app/features/profile/presentation/widgets/profile_account_section.dart';
import 'package:cinmovies_app/features/profile/presentation/widgets/profile_header.dart';
import 'package:cinmovies_app/features/profile/presentation/widgets/profile_movie_section.dart';
import 'package:cinmovies_app/features/profile/presentation/widgets/profile_stats_row.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteMovies = kHomeMovies.take(2).toList();
    final watchlistMovies = kHomeMovies.skip(2).take(2).toList();

    void openMovieDetails(HomeMovieModel movie) {
      context.pushNamed(Routes.movieDetails, arguments: movie);
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: ProfileHeader()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            const SliverToBoxAdapter(child: ProfileStatsRow()),
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
                onLogoutPressed: () {
                  context.pushNamedAndRemoveUntil(Routes.login);
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }
}
