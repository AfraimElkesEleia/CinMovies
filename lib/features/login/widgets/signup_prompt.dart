import 'package:flutter/material.dart';

import 'login_styles.dart';

class SignupPrompt extends StatelessWidget {
  const SignupPrompt({super.key, required this.onSignUpPressed});

  final VoidCallback onSignUpPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onSignUpPressed,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: "Don't have an account? ",
              style: TextStyle(
                color: LoginStyles.textColor.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
            const TextSpan(
              text: 'Sign Up',
              style: TextStyle(
                color: LoginStyles.accentColor,
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
