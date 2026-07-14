import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class BrowseSearchBar extends StatelessWidget {
  const BrowseSearchBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.surfaceBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.search_rounded, color: AppColors.iconMuted, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search movies, actors, genres...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.iconMuted, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
