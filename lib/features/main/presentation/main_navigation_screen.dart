import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/core/widgets/app_bottom_navigation_bar.dart';
import 'package:cinmovies_app/features/ai/presentation/ai_chat_screen.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
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
    final isGuest = serviceLocator<AuthRepository>().isGuest;
    return BlocProvider(
      create: (_) => MainNavigationCubit(),
      child: BlocBuilder<MainNavigationCubit, AppNavTab>(
        builder: (context, currentTab) {
          return PopScope(
            canPop: currentTab == AppNavTab.home,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop || currentTab == AppNavTab.home) return;
              context.read<MainNavigationCubit>().handleBlockedBackNavigation();
            },
            child: Scaffold(
              body: IndexedStack(
                index: AppNavTab.values.indexOf(currentTab),
                children: AppNavTab.values.map((tab) {
                  return switch (tab) {
                    AppNavTab.home => const HomeScreen(),
                    AppNavTab.browse => const BrowseScreen(),
                    AppNavTab.library =>
                      isGuest
                          ? const _GuestAccessGate(feature: 'your library')
                          : const LibraryScreen(),
                    AppNavTab.ai => const AiChatScreen(),
                    AppNavTab.profile =>
                      isGuest
                          ? const _GuestAccessGate(feature: 'your profile')
                          : const ProfileScreen(),
                  };
                }).toList(),
              ),
              bottomNavigationBar: AppBottomNavigationBar(
                currentTab: currentTab,
                onTabSelected: context.read<MainNavigationCubit>().selectTab,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GuestAccessGate extends StatelessWidget {
  const _GuestAccessGate({required this.feature});

  final String feature;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.loginPrimary,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sign in to open $feature',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your guest movie-chat history stays on this device and will not be merged into an account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _openLogin(context),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openLogin(BuildContext context) async {
    await serviceLocator<AuthRepository>().signOut();
    if (!context.mounted) return;
    context.pushNamedAndRemoveUntil(AppRoutes.login);
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
