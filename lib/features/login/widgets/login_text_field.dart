import 'package:flutter/material.dart';

import 'login_styles.dart';

class LoginTextField extends StatelessWidget {
  const LoginTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
  });

  final String label;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: LoginStyles.textColor)),
        const SizedBox(height: 8),
        TextField(
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: LoginStyles.textColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: LoginStyles.surfaceColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: LoginStyles.inputBorder(),
            enabledBorder: LoginStyles.inputBorder(),
            focusedBorder: LoginStyles.inputBorder(LoginStyles.primaryColor),
            hintText: hintText,
            hintStyle: const TextStyle(color: LoginStyles.hintColor),
            prefixIcon: Icon(prefixIcon, color: LoginStyles.textColor),
          ),
        ),
      ],
    );
  }
}
