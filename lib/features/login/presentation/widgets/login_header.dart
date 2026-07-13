import 'package:flutter/material.dart';

import 'login_styles.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: LoginStyles.borderRadius,
          child: Image.asset(
            'assets/images/app_logo.png',
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Welcome Back!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: LoginStyles.textColor,
          ),
        ),
        const Text(
          'Login to continue your movie journey',
          style: TextStyle(fontSize: 16, color: LoginStyles.textColor),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
