import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/movie_image.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_primitives.dart';
import 'package:flutter/material.dart';

class TrailerOverlay extends StatelessWidget {
  const TrailerOverlay({super.key, required this.movie, required this.onClose});

  final HomeMovieModel movie;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.black,
        child: Column(
          children: [
            Expanded(
              child: _TrailerPreview(movie: movie, onClose: onClose),
            ),
            const _TrailerControls(),
          ],
        ),
      ),
    );
  }
}

class _TrailerPreview extends StatelessWidget {
  const _TrailerPreview({required this.movie, required this.onClose});

  final HomeMovieModel movie;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: 0.6,
          child: MovieImage(path: movie.imageAsset),
        ),
        Center(
          child: Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: AppColors.loginPrimary.withValues(alpha: 0.92),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: AppColors.white,
              size: 36,
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              12,
              MediaQuery.paddingOf(context).top + 12,
              20,
              18,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.black.withValues(alpha: 0.82),
                  AppColors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.white,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Watching Trailer: ${movie.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TrailerControls extends StatelessWidget {
  const _TrailerControls();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      color: const Color(0xFF0A0A0F),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.35,
              minHeight: 4,
              backgroundColor: AppColors.surfaceBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.loginPrimary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Text(
                '1:24',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              Spacer(),
              Text(
                '3:48',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DetailsPlayerButton(icon: Icons.skip_previous_rounded),
              _PauseButton(),
              DetailsPlayerButton(icon: Icons.skip_next_rounded),
              DetailsPlayerButton(icon: Icons.volume_up_outlined),
              DetailsPlayerButton(icon: Icons.fullscreen_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  const _PauseButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        color: AppColors.loginPrimary,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.pause_rounded, color: AppColors.white, size: 28),
    );
  }
}
