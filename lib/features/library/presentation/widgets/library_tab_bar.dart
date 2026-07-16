import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/library/presentation/model/library_tab_model.dart';
import 'package:flutter/material.dart';

class LibraryTabBar extends StatelessWidget {
  const LibraryTabBar({super.key, required this.tabs});

  final List<LibraryTabModel> tabs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: AppColors.transparent,
        indicator: BoxDecoration(
          color: AppColors.loginPrimary,
          borderRadius: BorderRadius.circular(999),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        tabs: tabs
            .map(
              (tab) => Tab(
                height: 36,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(tab.label),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
