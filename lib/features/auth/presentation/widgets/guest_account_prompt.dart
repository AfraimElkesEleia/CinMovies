import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/core/widgets/app_snack_bar.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';

enum _GuestAccountDestination { login, register }

Future<void> showGuestAccountPrompt(
  BuildContext context, {
  required String feature,
}) async {
  final destination = await showModalBottomSheet<_GuestAccountDestination>(
    context: context,
    backgroundColor: AppColors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _GuestAccountSheet(feature: feature),
  );
  if (destination == null || !context.mounted) return;

  final route = switch (destination) {
    _GuestAccountDestination.login => AppRoutes.login,
    _GuestAccountDestination.register => AppRoutes.register,
  };
  await openAccountAccess(context, route);
}

Future<void> openAccountAccess(BuildContext context, String route) async {
  final result = await serviceLocator<AuthRepository>().leaveGuestMode();
  if (!context.mounted) return;

  result.fold(
    (failure) => AppSnackBar.showError(context, failure.message),
    (_) => context.pushNamedAndRemoveUntil(route),
  );
}

class _GuestAccountSheet extends StatelessWidget {
  const _GuestAccountSheet({required this.feature});

  final String feature;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.loginPrimary,
                size: 44,
              ),
              const SizedBox(height: 14),
              Text(
                'Sign in to $feature',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Guest mode keeps your movie chat and trailer history on this device. It will not be merged into an account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _GuestAccountDestination.login,
                  ),
                  child: const Text('Sign in'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _GuestAccountDestination.register,
                  ),
                  child: const Text('Create account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
