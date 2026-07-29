import 'dart:math' as math;

import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppSplashOverlay extends StatefulWidget {
  const AppSplashOverlay({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2200),
    this.reducedMotionDuration = const Duration(milliseconds: 450),
    this.onFinished,
  });

  static const visualKey = ValueKey<String>('cinmovies-splash-visual');

  final Widget child;
  final Duration duration;
  final Duration reducedMotionDuration;
  final VoidCallback? onFinished;

  @override
  State<AppSplashOverlay> createState() => _AppSplashOverlayState();
}

class _AppSplashOverlayState extends State<AppSplashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _entranceScale;
  late final Animation<double> _exitScale;
  late final Animation<double> _exitOpacity;
  late final Animation<double> _shineProgress;

  bool _animationScheduled = false;
  bool _completed = false;
  bool _isVisible = true;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener(_handleAnimationStatus);
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.30, curve: Curves.easeOutCubic),
    );
    _entranceScale = Tween<double>(begin: 0.84, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.32, curve: Curves.easeOutBack),
      ),
    );
    _exitScale = Tween<double>(begin: 1, end: 1.06).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.77, 1, curve: Curves.easeInCubic),
      ),
    );
    _exitOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.77, 1, curve: Curves.easeInOutCubic),
      ),
    );
    _shineProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.20, 0.58, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_animationScheduled) return;

    _animationScheduled = true;
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion) {
      _controller.duration = widget.reducedMotionDuration;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _completed) return;

    _completed = true;
    if (mounted) {
      setState(() => _isVisible = false);
    }
    widget.onFinished?.call();
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(excluding: _isVisible, child: widget.child),
        if (_isVisible)
          Positioned.fill(
            key: AppSplashOverlay.visualKey,
            child: AbsorbPointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final progress = _controller.value;
                  final overlayOpacity = _reduceMotion
                      ? 1 - Curves.easeInOutCubic.transform(progress)
                      : _exitOpacity.value;
                  final logoOpacity = _reduceMotion ? 1.0 : _logoOpacity.value;
                  final logoScale = _reduceMotion
                      ? 1.0
                      : _entranceScale.value * _exitScale.value;
                  final glowStrength = _reduceMotion
                      ? 0.25
                      : math.sin(math.pi * (progress / 0.72).clamp(0.0, 1.0));

                  return Opacity(
                    opacity: overlayOpacity.clamp(0.0, 1.0),
                    child: _SplashScene(
                      logoOpacity: logoOpacity,
                      logoScale: logoScale,
                      glowStrength: glowStrength,
                      shineProgress: _shineProgress.value,
                      showShine: !_reduceMotion,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _SplashScene extends StatelessWidget {
  const _SplashScene({
    required this.logoOpacity,
    required this.logoScale,
    required this.glowStrength,
    required this.shineProgress,
    required this.showShine,
  });

  final double logoOpacity;
  final double logoScale;
  final double glowStrength;
  final double shineProgress;
  final bool showShine;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.scaffoldBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF160A24),
              AppColors.scaffoldBackground,
              Color(0xFF200712),
            ],
          ),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.08),
              radius: 0.85,
              colors: [
                Color(0x296B34CE),
                Color(0x1FE11D48),
                AppColors.transparent,
              ],
              stops: [0, 0.52, 1],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final shortestSide = constraints.biggest.shortestSide;
              final logoSize = (shortestSide * 0.68)
                  .clamp(144.0, 280.0)
                  .toDouble();

              return Center(
                child: Semantics(
                  label: 'CinMovies',
                  image: true,
                  child: Opacity(
                    opacity: logoOpacity.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: logoScale,
                      child: _AnimatedLogo(
                        size: logoSize,
                        glowStrength: glowStrength,
                        shineProgress: shineProgress,
                        showShine: showShine,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AnimatedLogo extends StatelessWidget {
  const _AnimatedLogo({
    required this.size,
    required this.glowStrength,
    required this.shineProgress,
    required this.showShine,
  });

  final double size;
  final double glowStrength;
  final double shineProgress;
  final bool showShine;

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheSize = (size * devicePixelRatio).round();
    final cornerRadius = BorderRadius.circular(size * 0.11);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: cornerRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.comingSoonPurple.withValues(
              alpha: 0.16 + (glowStrength * 0.24),
            ),
            blurRadius: 24 + (glowStrength * 28),
            spreadRadius: 1 + (glowStrength * 3),
          ),
          BoxShadow(
            color: AppColors.loginPrimary.withValues(
              alpha: 0.12 + (glowStrength * 0.20),
            ),
            blurRadius: 32 + (glowStrength * 34),
            spreadRadius: glowStrength * 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: cornerRadius,
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/app_logo.png',
                cacheWidth: cacheSize,
                cacheHeight: cacheSize,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: AppColors.surface,
                  child: Icon(
                    Icons.movie_filter_rounded,
                    color: AppColors.white,
                    size: 72,
                  ),
                ),
              ),
              if (showShine)
                Positioned(
                  left: (-size * 0.34) + (shineProgress * size * 1.68),
                  top: -size * 0.18,
                  bottom: -size * 0.18,
                  width: size * 0.16,
                  child: Transform.rotate(
                    angle: -math.pi / 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.transparent,
                            AppColors.white.withValues(alpha: 0.44),
                            AppColors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
