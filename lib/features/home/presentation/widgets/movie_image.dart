import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/core/widgets/app_shimmer.dart';
import 'package:flutter/material.dart';

class MovieImage extends StatefulWidget {
  const MovieImage({super.key, required this.path, this.fit = BoxFit.cover});

  final String path;
  final BoxFit fit;

  @override
  State<MovieImage> createState() => _MovieImageState();
}

class _MovieImageState extends State<MovieImage> {
  bool _isLoaded = false;

  @override
  void didUpdateWidget(covariant MovieImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _isLoaded = false;
    }
  }

  void _markLoaded() {
    if (_isLoaded || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isLoaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.path.startsWith('http')
        ? Image.network(
            widget.path,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) {
              _markLoaded();
              return const _ImageFallback();
            },
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (frame != null || wasSynchronouslyLoaded) _markLoaded();
              return child;
            },
          )
        : Image.asset(
            widget.path,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) {
              _markLoaded();
              return const _ImageFallback();
            },
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (frame != null || wasSynchronouslyLoaded) _markLoaded();
              return child;
            },
          );

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedOpacity(
          opacity: _isLoaded ? 0 : 1,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: const _ImageLoadingPlaceholder(),
        ),
        AnimatedOpacity(
          opacity: _isLoaded ? 1 : 0,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          child: image,
        ),
      ],
    );
  }
}

class _ImageLoadingPlaceholder extends StatelessWidget {
  const _ImageLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(
      child: AppShimmerBox(height: double.infinity, radius: 0),
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
