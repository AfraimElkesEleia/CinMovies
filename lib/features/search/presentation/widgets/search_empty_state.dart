import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: AppColors.iconMuted,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Results Found',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try another keyword for "$query".',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.iconMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
