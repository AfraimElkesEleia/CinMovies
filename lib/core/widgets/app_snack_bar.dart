import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum AppSnackBarType { error, success, info }

class AppSnackBar {
  const AppSnackBar._();

  static void showError(BuildContext context, String message) {
    _show(context, message, AppSnackBarType.error);
  }

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppSnackBarType.success);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, AppSnackBarType.info);
  }

  static void _show(
    BuildContext context,
    String message,
    AppSnackBarType type,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_iconFor(type), color: AppColors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _backgroundColorFor(type),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static IconData _iconFor(AppSnackBarType type) {
    return switch (type) {
      AppSnackBarType.error => Icons.error_outline_rounded,
      AppSnackBarType.success => Icons.check_circle_outline_rounded,
      AppSnackBarType.info => Icons.info_outline_rounded,
    };
  }

  static Color _backgroundColorFor(AppSnackBarType type) {
    return switch (type) {
      AppSnackBarType.error => AppColors.loginPrimaryDark,
      AppSnackBarType.success => AppColors.successGreen,
      AppSnackBarType.info => AppColors.warningAmber,
    };
  }
}
