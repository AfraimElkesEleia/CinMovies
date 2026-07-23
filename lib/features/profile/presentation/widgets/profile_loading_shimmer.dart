import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ProfileLoadingShimmer extends StatefulWidget {
  const ProfileLoadingShimmer({super.key});

  @override
  State<ProfileLoadingShimmer> createState() => _ProfileLoadingShimmerState();
}

class _ProfileLoadingShimmerState extends State<ProfileLoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                AppColors.surface,
                AppColors.surfaceBorder,
                AppColors.surface,
              ],
              stops: const [0.18, 0.5, 0.82],
              transform: _SlidingGradientTransform(_controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: const CustomScrollView(
        physics: NeverScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _HeaderSkeleton()),
          SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(child: _StatsSkeleton()),
          SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(child: _MovieSectionSkeleton()),
          SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(child: _MovieSectionSkeleton()),
          SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(child: _AccountSkeleton()),
          SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0, 0);
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              _ShimmerBox(width: 88, height: 28, radius: 8),
              Spacer(),
              _ShimmerBox(width: 40, height: 40, radius: 14),
            ],
          ),
          SizedBox(height: 24),
          _ShimmerBox(width: 96, height: 96, radius: 30),
          SizedBox(height: 14),
          _ShimmerBox(width: 156, height: 24, radius: 8),
          SizedBox(height: 8),
          _ShimmerBox(width: 110, height: 14, radius: 6),
        ],
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == 2 ? 0 : 12),
              child: const _ShimmerBox(height: 88, radius: 16),
            ),
          );
        }),
      ),
    );
  }
}

class _MovieSectionSkeleton extends StatelessWidget {
  const _MovieSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _ShimmerBox(width: 86, height: 18, radius: 6),
              Spacer(),
              _ShimmerBox(width: 52, height: 18, radius: 6),
            ],
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 206,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                _MovieCardSkeleton(),
                SizedBox(width: 14),
                _MovieCardSkeleton(),
                SizedBox(width: 14),
                _MovieCardSkeleton(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MovieCardSkeleton extends StatelessWidget {
  const _MovieCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBox(width: 132, height: 168, radius: 16),
          SizedBox(height: 10),
          _ShimmerBox(width: 112, height: 14, radius: 5),
          SizedBox(height: 8),
          _ShimmerBox(width: 72, height: 12, radius: 5),
        ],
      ),
    );
  }
}

class _AccountSkeleton extends StatelessWidget {
  const _AccountSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBox(width: 78, height: 18, radius: 6),
          SizedBox(height: 12),
          _ShimmerBox(height: 212, radius: 18),
          SizedBox(height: 18),
          _ShimmerBox(height: 52, radius: 16),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    this.width,
    required this.height,
    required this.radius,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.surfaceBorder.withValues(alpha: 0.5)),
      ),
    );
  }
}
