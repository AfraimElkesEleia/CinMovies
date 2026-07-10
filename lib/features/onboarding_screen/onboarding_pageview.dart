import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/features/onboarding_screen/model/onboarding_screen_model.dart';
import 'package:cinmovies_app/features/onboarding_screen/widgets/onboarding_action_button.dart';
import 'package:cinmovies_app/features/onboarding_screen/widgets/onboarding_page_indicator.dart';
import 'package:cinmovies_app/features/onboarding_screen/widgets/onboarding_skip_button.dart';
import 'package:cinmovies_app/features/onboarding_screen/widgets/onboarding_slide.dart';
import 'package:flutter/material.dart';

class OnBoardingPageview extends StatefulWidget {
  const OnBoardingPageview({super.key});

  @override
  State<OnBoardingPageview> createState() => _OnBoardingPageviewState();
}

class _OnBoardingPageviewState extends State<OnBoardingPageview> {
  late final PageController controller;
  int _currentPage = 0;

  static const List<OnboardingScreenModel> _screens = [
    OnboardingScreenModel(
      title: 'Discover Movies\nYou\'ll Love',
      description:
          'Explore trending, top-rated, and upcoming movies in one beautiful app.',
      dotColor: Color(0xFFBD1A3F),
      imageAsset: 'assets/images/onB_screen1.jpg',
      buttonText: 'Next',
    ),
    OnboardingScreenModel(
      title: 'Build Your\nWatchlist',
      description:
          'Save movies you want to watch later and access them anytime, anywhere.',
      dotColor: Color(0xFF6B34CE),
      imageAsset: 'assets/images/onB_screen2.jpg',
      buttonText: 'Next',
    ),
    OnboardingScreenModel(
      title: 'Personalized\nFor You',
      description: 'Watch your favorite movies on any device, anytime.',
      dotColor: Color(0xFFD0870C),
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

  void _handleActionButtonPressed() {
    if (_currentPage == _screens.length - 1) {
      context.pushReplacementNamed(Routes.login);
      return;
    }

    controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B14),
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
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
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
                activeColor: _screens[_currentPage].dotColor,
              ),
              const SizedBox(height: 16),
              OnboardingActionButton(
                text: _screens[_currentPage].buttonText,
                backgroundColor: _screens[_currentPage].dotColor,
                onPressed: _handleActionButtonPressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
