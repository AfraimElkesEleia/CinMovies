import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class OnboardingSkipButton extends StatelessWidget {
  const OnboardingSkipButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.onboardingSkipOverlay,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(64)),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: const Text('Skip', style: TextStyle(color: AppColors.white)),
    );
  }
}
