import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class SearchHeader extends StatelessWidget {
  const SearchHeader({super.key, required this.onBackPressed});

  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackPressed,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Search',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
