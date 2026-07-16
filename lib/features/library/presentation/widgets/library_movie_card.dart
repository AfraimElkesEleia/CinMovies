import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/library/presentation/model/library_movie_model.dart';
import 'package:cinmovies_app/features/library/presentation/widgets/library_donut_progress.dart';
import 'package:flutter/material.dart';

class LibraryMovieCard extends StatelessWidget {
  const LibraryMovieCard({
    super.key,
    required this.movie,
    this.showDownloadActions = false,
  });

  final LibraryMovieModel movie;
  final bool showDownloadActions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 340;
        final posterWidth = isCompact ? 64.0 : 78.0;
        final posterHeight = isCompact ? 98.0 : 112.0;
        final horizontalGap = isCompact ? 8.0 : 12.0;
        final actionGap = isCompact ? 6.0 : 10.0;

        return Container(
          constraints: BoxConstraints(minHeight: isCompact ? 118 : 132),
          padding: EdgeInsets.all(isCompact ? 8 : 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MoviePoster(
                imageAsset: movie.imageAsset,
                width: posterWidth,
                height: posterHeight,
              ),
              SizedBox(width: horizontalGap),
              Expanded(
                child: _MovieCardContent(movie: movie, isCompact: isCompact),
              ),
              SizedBox(width: actionGap),
              _MovieCardActions(
                movie: movie,
                isCompact: isCompact,
                showDownloadActions: showDownloadActions,
              ),
            ],
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
      child: Image.asset(
        imageAsset,
        width: width,
        height: height,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _MovieCardContent extends StatelessWidget {
  const _MovieCardContent({required this.movie, required this.isCompact});

  final LibraryMovieModel movie;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          movie.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: isCompact ? 4 : 6),
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
        SizedBox(height: isCompact ? 10 : 18),
        _MovieMetaRow(movie: movie, isCompact: isCompact),
        SizedBox(height: isCompact ? 8 : 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: movie.progress.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: AppColors.surfaceBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.loginPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _MovieMetaRow extends StatelessWidget {
  const _MovieMetaRow({required this.movie, required this.isCompact});

  final LibraryMovieModel movie;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final status = Text(
      movie.status,
      maxLines: isCompact ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.loginPrimary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );

    if (isCompact) {
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
    required this.isCompact,
    required this.showDownloadActions,
  });

  final LibraryMovieModel movie;
  final bool isCompact;
  final bool showDownloadActions;

  @override
  Widget build(BuildContext context) {
    final progress = movie.progress.clamp(0.0, 1.0);

    if (showDownloadActions) {
      if (progress >= 1) {
        return _ActionIcon(
          icon: Icons.delete_outline_rounded,
          isCompact: isCompact,
        );
      }

      if (isCompact) {
        return _ActionIcon(
          icon: Icons.downloading_rounded,
          isCompact: isCompact,
        );
      }

      return LibraryDonutProgress(progress: progress, size: 46);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIcon(icon: movie.actionIcon, isCompact: isCompact),
        if (!isCompact) ...[
          const SizedBox(height: 32),
          LibraryDonutProgress(progress: progress, size: 46),
        ],
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.isCompact});

  final IconData icon;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCompact ? 32 : 34,
      height: isCompact ? 32 : 34,
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Icon(icon, color: AppColors.white, size: isCompact ? 18 : 19),
    );
  }
}
