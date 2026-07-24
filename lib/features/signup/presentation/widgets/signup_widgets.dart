import 'dart:typed_data';

import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/login/presentation/widgets/auth_divider.dart';
import 'package:cinmovies_app/features/login/presentation/widgets/login_styles.dart';
import 'package:cinmovies_app/features/login/presentation/widgets/login_with_button.dart';
import 'package:flutter/material.dart';

class SignupHeader extends StatelessWidget {
  const SignupHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Start discovering your next favorite movie',
          style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class SignupSocialActions extends StatelessWidget {
  const SignupSocialActions({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AuthDivider(text: 'or continue with'),
        SizedBox(height: 16),
        Row(
          children: [
            LoginWithButton(
              buttonText: 'Google',
              buttonIcon: 'assets/images/google_icon.png',
              onPressed: _noop,
            ),
            SizedBox(width: 8),
            LoginWithButton(
              buttonText: 'Facebook',
              buttonIcon: 'assets/images/facebook_icon.png',
              onPressed: _noop,
            ),
          ],
        ),
      ],
    );
  }

  static void _noop() {}
}

class SignupProfileImagePicker extends StatelessWidget {
  const SignupProfileImagePicker({
    super.key,
    required this.imageBytes,
    required this.onTap,
    required this.onRemove,
  });

  final Uint8List? imageBytes;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.loginPrimary,
                      AppColors.comingSoonPurple,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(27),
                  child: hasImage
                      ? Image.memory(imageBytes!, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.surface,
                          child: const Icon(
                            Icons.person_add_alt_1,
                            color: AppColors.textMuted,
                            size: 34,
                          ),
                        ),
                ),
              ),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: IconButton(
                tooltip: hasImage
                    ? 'Change profile image'
                    : 'Add profile image',
                onPressed: onTap,
                style: IconButton.styleFrom(
                  backgroundColor: LoginStyles.primaryColor,
                  foregroundColor: AppColors.white,
                  fixedSize: const Size(36, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
              ),
            ),
            if (hasImage)
              Positioned(
                left: -4,
                bottom: -4,
                child: IconButton(
                  tooltip: 'Remove profile image',
                  onPressed: onRemove,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textMuted,
                    fixedSize: const Size(36, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: onTap,
          icon: Icon(
            hasImage ? Icons.swap_horiz : Icons.add_photo_alternate_outlined,
            size: 18,
          ),
          label: Text(hasImage ? 'Change photo' : 'Add profile photo'),
          style: TextButton.styleFrom(
            foregroundColor: LoginStyles.primaryColor,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class SignupTermsAgreement extends StatelessWidget {
  const SignupTermsAgreement({
    super.key,
    required this.agreed,
    required this.onChanged,
  });

  final bool agreed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!agreed),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: agreed,
            activeColor: LoginStyles.primaryColor,
            side: const BorderSide(color: LoginStyles.borderColor),
            onChanged: (checked) => onChanged(checked ?? false),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text.rich(
                const TextSpan(
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  children: [
                    TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(color: LoginStyles.primaryColor),
                    ),
                    TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(color: LoginStyles.primaryColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginPrompt extends StatelessWidget {
  const LoginPrompt({super.key, required this.onLoginPressed});

  final VoidCallback onLoginPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onLoginPressed,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Already have an account? ',
              style: TextStyle(
                color: LoginStyles.textColor.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
            const TextSpan(
              text: 'Login',
              style: TextStyle(
                color: LoginStyles.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
