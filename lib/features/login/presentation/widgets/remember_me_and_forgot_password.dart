import 'package:flutter/material.dart';

import 'login_styles.dart';

class RememberMeAndForgotPassword extends StatelessWidget {
  const RememberMeAndForgotPassword({
    super.key,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.onForgotPasswordPressed,
  });

  final bool rememberMe;
  final ValueChanged<bool> onRememberMeChanged;
  final VoidCallback? onForgotPasswordPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: rememberMe,
              activeColor: LoginStyles.primaryColor,
              side: const BorderSide(color: LoginStyles.hintColor),
              onChanged: (value) => onRememberMeChanged(value ?? false),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              visualDensity: VisualDensity.compact,
            ),
            const Text(
              'Remember Me',
              style: TextStyle(color: LoginStyles.textColor),
            ),
          ],
        ),
        TextButton(
          onPressed: onForgotPasswordPressed,
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              color: LoginStyles.accentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
