import 'package:cinmovies_app/core/widgets/app_shimmer.dart';
import 'package:flutter/material.dart';

class MovieDetailsLoadingShimmer extends StatelessWidget {
  const MovieDetailsLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(
      child: CustomScrollView(
        physics: NeverScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: AppShimmerBox(height: 280, radius: 0)),
          SliverToBoxAdapter(child: SizedBox(height: 18)),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppShimmerBox(width: 68, height: 24, radius: 999),
                      SizedBox(width: 8),
                      AppShimmerBox(width: 82, height: 24, radius: 999),
                    ],
                  ),
                  SizedBox(height: 16),
                  AppShimmerBox(width: 230, height: 28, radius: 8),
                  SizedBox(height: 12),
                  AppShimmerBox(width: 180, height: 14, radius: 6),
                  SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: AppShimmerBox(height: 52, radius: 16)),
                      SizedBox(width: 12),
                      AppShimmerBox(width: 56, height: 52, radius: 16),
                    ],
                  ),
                  SizedBox(height: 22),
                  Row(
                    children: [
                      AppShimmerBox(width: 80, height: 28, radius: 999),
                      SizedBox(width: 10),
                      AppShimmerBox(width: 54, height: 28, radius: 999),
                      SizedBox(width: 10),
                      AppShimmerBox(width: 72, height: 28, radius: 999),
                    ],
                  ),
                  SizedBox(height: 18),
                  AppShimmerBox(height: 14, radius: 6),
                  SizedBox(height: 10),
                  AppShimmerBox(height: 14, radius: 6),
                  SizedBox(height: 10),
                  AppShimmerBox(width: 220, height: 14, radius: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
