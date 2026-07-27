import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/local/local_preferences_service.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/onboarding/model/onboarding_page_content.dart';
import 'package:cinmovies_app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:cinmovies_app/features/onboarding/widgets/onboarding_action_button.dart';
import 'package:cinmovies_app/features/onboarding/widgets/onboarding_page_indicator.dart';
import 'package:cinmovies_app/features/onboarding/widgets/onboarding_skip_button.dart';
import 'package:cinmovies_app/features/onboarding/widgets/onboarding_slide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(serviceLocator<LocalPreferencesService>()),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  late final PageController _pageController;

  static const List<OnboardingPageContent> _pages = [
    OnboardingPageContent(
      title: 'Discover Movies\nYou\'ll Love',
      description:
          'Explore trending, top-rated, and upcoming movies in one beautiful app.',
      dotColor: AppColors.onboardingCrimson,
      imageAsset: 'assets/images/onB_screen1.jpg',
      buttonText: 'Next',
    ),
    OnboardingPageContent(
      title: 'Build Your\nWatchlist',
      description:
          'Save movies you want to watch later and access them anytime, anywhere.',
      dotColor: AppColors.onboardingPurple,
      imageAsset: 'assets/images/onB_screen2.jpg',
      buttonText: 'Next',
    ),
    OnboardingPageContent(
      title: 'Personalized\nFor You',
      description: 'Watch your favorite movies on any device, anytime.',
      dotColor: AppColors.onboardingAmber,
      imageAsset: 'assets/images/onB_screen3.jpg',
      buttonText: 'Get Started',
    ),
  ];

  @override
  void initState() {
    _pageController = PageController();
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToLastPage() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleActionButtonPressed(BuildContext context) async {
    final navigator = Navigator.of(context);
    final currentPage = context.read<OnboardingCubit>().state.pageIndex;
    if (currentPage == _pages.length - 1) {
      await context.read<OnboardingCubit>().markPassed();
      if (!mounted) return;
      navigator.pushReplacementNamed(AppRoutes.preferenceOnboarding);
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        return Scaffold(
          body: Column(
            children: [
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [OnboardingSkipButton(onPressed: _goToLastPage)],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: context.read<OnboardingCubit>().setPage,
                  itemBuilder: (context, index) {
                    return OnboardingSlide(page: _pages[index]);
                  },
                ),
              ),
              Column(
                children: [
                  OnboardingPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    activeColor: _pages[state.pageIndex].dotColor,
                  ),
                  const SizedBox(height: 16),
                  OnboardingActionButton(
                    text: _pages[state.pageIndex].buttonText,
                    backgroundColor: _pages[state.pageIndex].dotColor,
                    onPressed: () => _handleActionButtonPressed(context),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
