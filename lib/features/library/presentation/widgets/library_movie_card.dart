import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/movie_image.dart';
import 'package:cinmovies_app/features/library/presentation/model/library_movie_model.dart';
import 'package:flutter/material.dart';

class LibraryMovieCard extends StatelessWidget {
  const LibraryMovieCard({
    super.key,
    required this.movie,
    required this.heroTag,
    required this.onPressed,
    required this.onRemovePressed,
    this.showDownloadActions = false,
  });

  final LibraryMovieModel movie;
  final String heroTag;
  final VoidCallback onPressed;
  final VoidCallback onRemovePressed;
  final bool showDownloadActions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTight = constraints.maxWidth < 360;
        final posterWidth = isTight ? 56.0 : 72.0;
        final posterHeight = isTight ? 84.0 : 108.0;
        final horizontalGap = isTight ? 8.0 : 12.0;

        return Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              padding: EdgeInsets.all(isTight ? 8 : 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: heroTag,
                    child: _MoviePoster(
                      imageAsset: movie.imageAsset,
                      width: posterWidth,
                      height: posterHeight,
                    ),
                  ),
                  SizedBox(width: horizontalGap),
                  Expanded(
                    child: _MovieCardContent(
                      movie: movie,
                      isTight: isTight,
                      showDownloadActions: showDownloadActions,
                      onRemovePressed: onRemovePressed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MoviePoster extends StatelessWidget {
  const _MoviePoster({
    required this.imageAsset,
    required this.width,
    required this.height,
  });

  final String imageAsset;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: width,
        height: height,
        child: MovieImage(path: imageAsset),
      ),
    );
  }
}

class _MovieCardContent extends StatelessWidget {
  const _MovieCardContent({
    required this.movie,
    required this.isTight,
    required this.showDownloadActions,
    required this.onRemovePressed,
  });

  final LibraryMovieModel movie;
  final bool isTight;
  final bool showDownloadActions;
  final VoidCallback onRemovePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          movie.title,
          maxLines: isTight ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: isTight ? 3 : 5),
        Text(
          '${movie.year} • ${movie.genre}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: isTight ? 8 : 12),
        _MovieMetaRow(movie: movie, isTight: isTight),
        SizedBox(height: isTight ? 8 : 10),
        _MovieCardActions(
          movie: movie,
          isTight: isTight,
          showDownloadActions: showDownloadActions,
          onRemovePressed: onRemovePressed,
        ),
      ],
    );
  }
}

class _MovieMetaRow extends StatelessWidget {
  const _MovieMetaRow({required this.movie, required this.isTight});

  final LibraryMovieModel movie;
  final bool isTight;

  @override
  Widget build(BuildContext context) {
    final status = Text(
      movie.status,
      maxLines: isTight ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.loginPrimary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );

    if (isTight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DurationLabel(duration: movie.duration),
          const SizedBox(height: 3),
          status,
        ],
      );
    }

    return Row(
      children: [
        _DurationLabel(duration: movie.duration),
        const SizedBox(width: 10),
        Flexible(child: status),
      ],
    );
  }
}

class _DurationLabel extends StatelessWidget {
  const _DurationLabel({required this.duration});

  final String duration;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, color: AppColors.iconMuted, size: 15),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            duration,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.iconMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MovieCardActions extends StatelessWidget {
  const _MovieCardActions({
    required this.movie,
    required this.isTight,
    required this.showDownloadActions,
    required this.onRemovePressed,
  });

  final LibraryMovieModel movie;
  final bool isTight;
  final bool showDownloadActions;
  final VoidCallback onRemovePressed;

  @override
  Widget build(BuildContext context) {
    if (showDownloadActions) {
      return _ActionIcon(
        icon: Icons.delete_outline_rounded,
        isTight: isTight,
        onPressed: onRemovePressed,
      );
    }

    return _ActionIcon(
      icon: movie.actionIcon,
      isTight: isTight,
      onPressed: onRemovePressed,
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.isTight,
    required this.onPressed,
  });

  final IconData icon;
  final bool isTight;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: isTight ? 34 : 38,
          height: isTight ? 34 : 38,
          decoration: BoxDecoration(
            color: AppColors.scaffoldBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Icon(icon, color: AppColors.white, size: isTight ? 18 : 20),
        ),
      ),
    );
  }
}
