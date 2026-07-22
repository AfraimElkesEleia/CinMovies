import 'package:flutter/material.dart';

import '../../features/login/presentation/widgets/login_styles.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final String hintText;
  final IconData prefixIcon;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: LoginStyles.textColor)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          style: const TextStyle(color: LoginStyles.textColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: LoginStyles.surfaceColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: LoginStyles.inputBorder(),
            enabledBorder: LoginStyles.inputBorder(LoginStyles.borderColor),
            focusedBorder: LoginStyles.inputBorder(LoginStyles.primaryColor),
            hintText: hintText,
            hintStyle: const TextStyle(color: LoginStyles.hintColor),
            prefixIcon: Icon(prefixIcon, color: LoginStyles.iconColor),
          ),
        ),
      ],
    );
  }
}
