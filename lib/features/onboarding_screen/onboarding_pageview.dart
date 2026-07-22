import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/local/local_preferences_service.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/onboarding_screen/model/onboarding_screen_model.dart';
import 'package:cinmovies_app/features/onboarding_screen/presentation/cubit/onboarding_cubit.dart';
import 'package:cinmovies_app/features/onboarding_screen/widgets/onboarding_action_button.dart';
import 'package:cinmovies_app/features/onboarding_screen/widgets/onboarding_page_indicator.dart';
import 'package:cinmovies_app/features/onboarding_screen/widgets/onboarding_skip_button.dart';
import 'package:cinmovies_app/features/onboarding_screen/widgets/onboarding_slide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OnBoardingPageview extends StatelessWidget {
  const OnBoardingPageview({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(sl<LocalPreferencesService>()),
      child: const _OnBoardingView(),
    );
  }
}

class _OnBoardingView extends StatefulWidget {
  const _OnBoardingView();

  @override
  State<_OnBoardingView> createState() => _OnBoardingViewState();
}

class _OnBoardingViewState extends State<_OnBoardingView> {
  late final PageController controller;

  static const List<OnboardingScreenModel> _screens = [
    OnboardingScreenModel(
      title: 'Discover Movies\nYou\'ll Love',
      description:
          'Explore trending, top-rated, and upcoming movies in one beautiful app.',
      dotColor: AppColors.onboardingCrimson,
      imageAsset: 'assets/images/onB_screen1.jpg',
      buttonText: 'Next',
    ),
    OnboardingScreenModel(
      title: 'Build Your\nWatchlist',
      description:
          'Save movies you want to watch later and access them anytime, anywhere.',
      dotColor: AppColors.onboardingPurple,
      imageAsset: 'assets/images/onB_screen2.jpg',
      buttonText: 'Next',
    ),
    OnboardingScreenModel(
      title: 'Personalized\nFor You',
      description: 'Watch your favorite movies on any device, anytime.',
      dotColor: AppColors.onboardingAmber,
      imageAsset: 'assets/images/onB_screen3.jpg',
      buttonText: 'Get Started',
    ),
  ];

  @override
  void initState() {
    controller = PageController();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _goToLastPage() {
    controller.animateToPage(
      _screens.length - 1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleActionButtonPressed(BuildContext context) async {
    final navigator = Navigator.of(context);
    final currentPage = context.read<OnboardingCubit>().state.pageIndex;
    if (currentPage == _screens.length - 1) {
      await context.read<OnboardingCubit>().markPassed();
      if (!mounted) return;
      navigator.pushReplacementNamed(Routes.preferenceOnboarding);
      return;
    }

    controller.nextPage(
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
                  controller: controller,
                  itemCount: _screens.length,
                  onPageChanged: context.read<OnboardingCubit>().setPage,
                  itemBuilder: (context, index) {
                    return OnboardingSlide(screen: _screens[index]);
                  },
                ),
              ),
              Column(
                children: [
                  OnboardingPageIndicator(
                    controller: controller,
                    count: _screens.length,
                    activeColor: _screens[state.pageIndex].dotColor,
                  ),
                  const SizedBox(height: 16),
                  OnboardingActionButton(
                    text: _screens[state.pageIndex].buttonText,
                    backgroundColor: _screens[state.pageIndex].dotColor,
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
