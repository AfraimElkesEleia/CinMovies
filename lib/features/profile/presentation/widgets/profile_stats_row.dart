import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({
    super.key,
    this.watchedCount = 0,
    this.watchlistCount = 0,
    this.reviewCount = 0,
  });

  final int watchedCount;
  final int watchlistCount;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _ProfileStatCard(
              value: watchedCount.toString(),
              label: 'Watched',
              icon: Icons.visibility_outlined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ProfileStatCard(
              value: watchlistCount.toString(),
              label: 'Watchlist',
              icon: Icons.bookmark_border_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ProfileStatCard(
              value: reviewCount.toString(),
              label: 'Reviews',
              icon: Icons.star_border_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.loginPrimary, size: 21),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.iconMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
