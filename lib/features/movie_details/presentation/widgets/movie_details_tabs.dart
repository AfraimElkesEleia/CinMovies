import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/movie_details/presentation/model/movie_details_tab.dart';
import 'package:flutter/material.dart';

class MovieDetailsTabs extends StatelessWidget {
  const MovieDetailsTabs({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
  });

  final MovieDetailsTab activeTab;
  final ValueChanged<MovieDetailsTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 4),
      child: Row(
        children: List.generate(MovieDetailsTab.values.length, (index) {
          final tab = MovieDetailsTab.values[index];
          final isActive = tab == activeTab;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : 4),
              child: TextButton(
                onPressed: () => onTabSelected(tab),
                style: TextButton.styleFrom(
                  backgroundColor:
                      isActive ? AppColors.surfaceBorder : AppColors.transparent,
                  foregroundColor:
                      isActive ? AppColors.white : AppColors.iconMuted,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isActive
                          ? AppColors.surfaceBorder
                          : AppColors.transparent,
                    ),
                  ),
                  textStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                child: Text(tab.label),
              ),
            ),
          );
        }),
      ),
    );
  }
}
