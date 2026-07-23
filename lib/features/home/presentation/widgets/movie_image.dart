import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class MovieImage extends StatelessWidget {
  const MovieImage({super.key, required this.path, this.fit = BoxFit.cover});

  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => const _ImageFallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const _ImageFallback();
        },
      );
    }

    return Image.asset(
      path,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const _ImageFallback(),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: AppColors.surface),
      child: Center(
        child: Icon(
          Icons.movie_creation_outlined,
          color: AppColors.textMuted,
          size: 34,
        ),
      ),
    );
  }
}
