import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class OnboardingActionButton extends StatelessWidget {
  const OnboardingActionButton({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.onPressed,
  });

  final String text;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 32),
      child: TweenAnimationBuilder<Color?>(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        tween: ColorTween(end: backgroundColor),
        builder: (context, color, child) {
          return ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color ?? backgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}
