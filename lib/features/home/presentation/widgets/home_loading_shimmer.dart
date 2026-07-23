import 'package:cinmovies_app/core/widgets/app_shimmer.dart';
import 'package:flutter/material.dart';

class HomeLoadingShimmer extends StatelessWidget {
  const HomeLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(
      child: CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _TopBarSkeleton()),
          SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverToBoxAdapter(child: _HeroSkeleton()),
          SliverToBoxAdapter(child: SizedBox(height: 26)),
          SliverToBoxAdapter(child: _MovieSectionSkeleton()),
          SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(child: _MovieSectionSkeleton()),
          SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }
}

class _TopBarSkeleton extends StatelessWidget {
  const _TopBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmerBox(width: 96, height: 13, radius: 6),
                SizedBox(height: 8),
                AppShimmerBox(width: 220, height: 18, radius: 7),
              ],
            ),
          ),
          AppShimmerBox(width: 40, height: 40, radius: 14),
          SizedBox(width: 12),
          AppShimmerBox(width: 40, height: 40, radius: 14),
        ],
      ),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: AppShimmerBox(height: 228, radius: 24),
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
              AppShimmerBox(width: 116, height: 18, radius: 6),
              Spacer(),
              AppShimmerBox(width: 52, height: 18, radius: 6),
            ],
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          height: 206,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                AppShimmerBox(width: 148, height: 206, radius: 16),
                SizedBox(width: 14),
                AppShimmerBox(width: 148, height: 206, radius: 16),
                SizedBox(width: 14),
                AppShimmerBox(width: 148, height: 206, radius: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
