import 'package:flutter/material.dart';

import 'login_styles.dart';

class LoginWithButton extends StatelessWidget {
  const LoginWithButton({
    super.key,
    required this.buttonText,
    required this.buttonIcon,
    required this.onPressed,
  });

  final String buttonText;
  final String buttonIcon;
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
            Image.asset(buttonIcon, width: 24, height: 24),
            const SizedBox(width: 8),
            Text(
              buttonText,
              style: const TextStyle(color: LoginStyles.textColor),
            ),
          ],
        ),
      ),
    );
  }
}
