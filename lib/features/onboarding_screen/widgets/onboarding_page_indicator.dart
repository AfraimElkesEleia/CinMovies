import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    super.key,
    required this.controller,
    required this.count,
    required this.activeColor,
  });

  final PageController controller;
  final int count;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<Color?>(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        tween: ColorTween(end: activeColor),
        builder: (context, color, child) {
          return SmoothPageIndicator(
            controller: controller,
            count: count,
            effect: ExpandingDotsEffect(
              dotHeight: 8,
              dotWidth: 8,
              activeDotColor: color ?? activeColor,
              dotColor: Colors.grey,
            ),
          );
        },
      ),
    );
  }
}
