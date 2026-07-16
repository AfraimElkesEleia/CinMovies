import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/core/widgets/app_bottom_navigation_bar.dart';
import 'package:cinmovies_app/features/browse/presentation/browse_screen.dart';
import 'package:cinmovies_app/features/home/presentation/home_screen.dart';
import 'package:cinmovies_app/features/library/presentation/library_screen.dart';
import 'package:flutter/material.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  AppNavTab currentTab = AppNavTab.home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: AppNavTab.values.indexOf(currentTab),
        children: AppNavTab.values.map((tab) {
          if (tab == AppNavTab.home) {
            return const HomeScreen();
          }

          if (tab == AppNavTab.browse) {
            return const BrowseScreen();
          }

          if (tab == AppNavTab.library) {
            return const LibraryScreen();
          }

          return _MainTabPlaceholder(tab: tab);
        }).toList(),
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentTab: currentTab,
        onTabSelected: (tab) {
          setState(() {
            currentTab = tab;
          });
        },
      ),
    );
  }
}

class _MainTabPlaceholder extends StatelessWidget {
  const _MainTabPlaceholder({required this.tab});

  final AppNavTab tab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: Text(
            tab.label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
