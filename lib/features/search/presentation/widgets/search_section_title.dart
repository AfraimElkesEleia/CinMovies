import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class SearchSectionTitle extends StatelessWidget {
  const SearchSectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
