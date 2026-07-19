import 'dart:async';

import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/movie_rating.dart';
import 'package:flutter/material.dart';

class HomeMovieCarousel extends StatefulWidget {
  const HomeMovieCarousel({
    super.key,
    required this.movies,
    required this.onMoviePressed,
  });

  final List<HomeMovieModel> movies;
  final ValueChanged<HomeMovieModel> onMoviePressed;

  @override
  State<HomeMovieCarousel> createState() => _HomeMovieCarouselState();
}

class _HomeMovieCarouselState extends State<HomeMovieCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_controller.hasClients || widget.movies.isEmpty) return;

      final nextIndex = (_currentIndex + 1) % widget.movies.length;
      _controller.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 228,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.movies.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _HeroMovieCard(
                  movie: widget.movies[index],
                  onPressed: () => widget.onMoviePressed(widget.movies[index]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.movies.length, (index) {
            final isActive = index == _currentIndex;

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
  }
}

class _HeroMovieCard extends StatelessWidget {
  const _HeroMovieCard({required this.movie, required this.onPressed});

  final HomeMovieModel movie;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(movie.imageAsset, fit: BoxFit.cover),
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
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
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
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.12),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.18),
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.bookmark_border_rounded,
                        color: AppColors.white,
                      ),
                    ),
                  ],
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
