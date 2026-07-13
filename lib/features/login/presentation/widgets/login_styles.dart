import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class LoginStyles {
  const LoginStyles._();

  static const Color surfaceColor = AppColors.surface;
  static const Color primaryColor = AppColors.loginPrimary;
  static const Color accentColor = AppColors.loginPrimary;
  static const Color textColor = AppColors.white;
  static const Color hintColor = AppColors.textMuted;
  static const Color borderColor = AppColors.surfaceBorder;
  static const Color iconColor = AppColors.iconMuted;

  static final BorderRadius borderRadius = BorderRadius.circular(16);

  static OutlineInputBorder inputBorder([Color color = AppColors.transparent]) {
    return OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: color, width: 0.5),
    );
  }
}
