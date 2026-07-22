import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/core/widgets/app_bottom_navigation_bar.dart';
import 'package:cinmovies_app/features/ai/presentation/ai_chat_screen.dart';
import 'package:cinmovies_app/features/browse/presentation/browse_screen.dart';
import 'package:cinmovies_app/features/home/presentation/home_screen.dart';
import 'package:cinmovies_app/features/library/presentation/library_screen.dart';
import 'package:cinmovies_app/features/main/presentation/cubit/main_navigation_cubit.dart';
import 'package:cinmovies_app/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MainNavigationCubit(),
      child: BlocBuilder<MainNavigationCubit, AppNavTab>(
        builder: (context, currentTab) {
          return Scaffold(
            body: IndexedStack(
              index: AppNavTab.values.indexOf(currentTab),
              children: AppNavTab.values.map((tab) {
                return switch (tab) {
                  AppNavTab.home => const HomeScreen(),
                  AppNavTab.browse => const BrowseScreen(),
                  AppNavTab.library => const LibraryScreen(),
                  AppNavTab.ai => const AiChatScreen(),
                  AppNavTab.profile => const ProfileScreen(),
                };
              }).toList(),
            ),
            bottomNavigationBar: AppBottomNavigationBar(
              currentTab: currentTab,
              onTabSelected: context.read<MainNavigationCubit>().selectTab,
            ),
          );
        },
      ),
    );
  }
}

class MainTabPlaceholder extends StatelessWidget {
  const MainTabPlaceholder({super.key, required this.tab});

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
