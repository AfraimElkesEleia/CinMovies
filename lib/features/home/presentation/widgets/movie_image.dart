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
  static const _fadeDuration = Duration(milliseconds: 420);

  late String _activePath;
  String? _nextPath;
  bool _activeLoaded = false;
  bool _nextLoaded = false;

  @override
  void initState() {
    super.initState();
    _activePath = widget.path;
  }

  @override
  void didUpdateWidget(covariant MovieImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path == widget.path) return;

    if (!_activeLoaded) {
      _activePath = widget.path;
      _nextPath = null;
      _nextLoaded = false;
      return;
    }

    _nextPath = widget.path;
    _nextLoaded = false;
  }

  void _markActiveLoaded() {
    if (_activeLoaded || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_activeLoaded) setState(() => _activeLoaded = true);
    });
  }

  void _markNextLoaded(String path) {
    if (_nextLoaded || !mounted || _nextPath != path) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _nextLoaded || _nextPath != path) return;
      setState(() => _nextLoaded = true);
      Future<void>.delayed(_fadeDuration, () {
        if (!mounted || _nextPath != path) return;
        setState(() {
          _activePath = path;
          _nextPath = null;
          _nextLoaded = false;
          _activeLoaded = true;
        });
      });
    });
  }

  Widget _buildImage(String path, VoidCallback onLoaded) {
    return path.startsWith('http')
        ? Image.network(
            path,
            key: ValueKey(path),
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) {
              onLoaded();
              return const _ImageFallback();
            },
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (frame != null || wasSynchronouslyLoaded) onLoaded();
              return child;
            },
          )
        : Image.asset(
            path,
            key: ValueKey(path),
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) {
              onLoaded();
              return const _ImageFallback();
            },
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (frame != null || wasSynchronouslyLoaded) onLoaded();
              return child;
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    final nextPath = _nextPath;
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedOpacity(
          opacity: _activeLoaded ? 0 : 1,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: const _ImageLoadingPlaceholder(),
        ),
        AnimatedOpacity(
          opacity: _activeLoaded ? 1 : 0,
          duration: _fadeDuration,
          curve: Curves.easeOutCubic,
          child: _buildImage(_activePath, _markActiveLoaded),
        ),
        if (nextPath != null)
          AnimatedOpacity(
            opacity: _nextLoaded ? 1 : 0,
            duration: _fadeDuration,
            curve: Curves.easeOutCubic,
            child: _buildImage(nextPath, () => _markNextLoaded(nextPath)),
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
