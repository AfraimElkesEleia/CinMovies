import 'package:flutter/material.dart';

import 'login_styles.dart';

class LoginOptionsRow extends StatelessWidget {
  const LoginOptionsRow({
    super.key,
    required this.onForgotPasswordPressed,
  });

  final VoidCallback? onForgotPasswordPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onForgotPasswordPressed,
        child: const Text(
          'Forgot Password?',
          style: TextStyle(
            color: LoginStyles.accentColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
