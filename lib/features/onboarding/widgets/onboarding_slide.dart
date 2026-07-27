import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/onboarding/model/onboarding_page_content.dart';
import 'package:flutter/material.dart';

class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({super.key, required this.page});

  final OnboardingPageContent page;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1.5,
              child: Image.asset(page.imageAsset, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: const TextStyle(fontSize: 16, color: AppColors.white),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
