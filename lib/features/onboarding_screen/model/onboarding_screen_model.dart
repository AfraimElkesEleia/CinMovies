import 'package:flutter/material.dart';

class OnboardingScreenModel {
  final String title;
  final String description;
  final Color dotColor;
  final String imageAsset;
  final String buttonText;

  const OnboardingScreenModel({
    required this.title,
    required this.description,
    required this.dotColor,
    required this.imageAsset,
    required this.buttonText,
  });
}
