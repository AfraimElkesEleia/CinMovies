import 'dart:async';

import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/home/presentation/cubit/home_carousel_cubit.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/movie_image.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/movie_rating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeMovieCarousel extends StatefulWidget {
  const HomeMovieCarousel({
    super.key,
    required this.movies,
    required this.onMoviePressed,
    required this.heroTagFor,
  });

  final List<Movie> movies;
  final void Function(Movie movie, String heroTag) onMoviePressed;
  final String Function(Movie movie, int index) heroTagFor;

  @override
  State<HomeMovieCarousel> createState() => _HomeMovieCarouselState();
}

class _HomeMovieCarouselState extends State<HomeMovieCarousel> {
  late final PageController _controller;
  Timer? _timer;
  late final HomeCarouselCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = HomeCarouselCubit();
    _controller = PageController();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cubit.close();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_controller.hasClients || widget.movies.isEmpty) return;

      final nextIndex = (_cubit.state + 1) % widget.movies.length;
      _controller.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCarouselCubit, int>(
      bloc: _cubit,
      builder: (context, currentIndex) {
        return Column(
          children: [
            SizedBox(
              height: 228,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.movies.length,
                onPageChanged: _cubit.setIndex,
                itemBuilder: (context, index) {
                  final movie = widget.movies[index];
                  final heroTag = widget.heroTagFor(movie, index);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _HeroMovieCard(
                      movie: movie,
                      heroTag: heroTag,
                      onPressed: () => widget.onMoviePressed(movie, heroTag),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.movies.length, (index) {
                final isActive = index == currentIndex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 18 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.loginPrimary
                        : AppColors.white.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _HeroMovieCard extends StatelessWidget {
  const _HeroMovieCard({
    required this.movie,
    required this.heroTag,
    required this.onPressed,
  });

  final Movie movie;
  final String heroTag;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: heroTag,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: MovieImage(path: movie.imageAsset),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.scaffoldBackground.withValues(alpha: 0.04),
                  AppColors.scaffoldBackground.withValues(alpha: 0.98),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final genre in movie.genres.take(2))
                      _GenreChip(label: genre),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ratingAmber.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: MovieRating(rating: movie.rating),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.loginPrimary,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.loginPrimary.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
