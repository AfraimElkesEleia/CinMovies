import 'package:cinmovies_app/core/widgets/app_shimmer.dart';
import 'package:flutter/material.dart';

class SearchLoadingShimmer extends StatelessWidget {
  const SearchLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 6,
        separatorBuilder: _separatorBuilder,
        itemBuilder: _itemBuilder,
      ),
    );
  }

  static Widget _separatorBuilder(BuildContext context, int index) {
    return const SizedBox(height: 10);
  }

  static Widget _itemBuilder(BuildContext context, int index) {
    return const Row(
      children: [
        AppShimmerBox(width: 62, height: 84, radius: 12),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppShimmerBox(height: 15, radius: 6),
              SizedBox(height: 10),
              AppShimmerBox(width: 130, height: 12, radius: 5),
              SizedBox(height: 12),
              AppShimmerBox(width: 64, height: 12, radius: 5),
            ],
          ),
        ),
      ],
    );
  }
}
