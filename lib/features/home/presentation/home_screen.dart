import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/home/presentation/data/home_mock_data.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/home_movie_carousel.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/home_section_header.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/movie_card.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void openDetails(Object movie) {
      context.pushNamed(Routes.movieDetails, arguments: movie);
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _HomeTopBar()),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: HomeMovieCarousel(
                movies: kHomeMovies,
                onMoviePressed: openDetails,
              ),
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
              child: SizedBox(
                height: 206,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: kHomeMovies.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    return MovieCard(
                      movie: kHomeMovies[index],
                      onTap: () => openDetails(kHomeMovies[index]),
                    );
                  },
                ),
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
              child: SizedBox(
                height: 206,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: kHomeMovies.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final movie = kHomeMovies.reversed.toList()[index];
                    return MovieCard(
                      movie: movie,
                      onTap: () => openDetails(movie),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
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
