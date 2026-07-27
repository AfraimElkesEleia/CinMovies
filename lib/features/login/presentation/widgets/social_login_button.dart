import 'package:flutter/material.dart';

import 'login_styles.dart';

class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
    required this.label,
    required this.iconAssetPath,
    required this.onPressed,
  });

  final String label;
  final String iconAssetPath;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: LoginStyles.surfaceColor,
          minimumSize: const Size(double.infinity, 50),
          side: BorderSide(
            color: LoginStyles.textColor.withValues(alpha: 0.5),
            width: 0.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: LoginStyles.borderRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconAssetPath, width: 24, height: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: LoginStyles.textColor),
            ),
          ],
        ),
      ),
    );
  }
}
