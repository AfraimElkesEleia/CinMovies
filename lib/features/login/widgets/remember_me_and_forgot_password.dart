import 'package:flutter/material.dart';

import 'login_styles.dart';

class RememberMeAndForgotPassword extends StatelessWidget {
  const RememberMeAndForgotPassword({
    super.key,
    required this.rememberMeCheckBox,
    required this.onForgotPasswordPressed,
  });

  final ValueNotifier<bool> rememberMeCheckBox;
  final VoidCallback? onForgotPasswordPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            RememberMeCheckBox(rememberMeCheckBox: rememberMeCheckBox),
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

class RememberMeCheckBox extends StatelessWidget {
  const RememberMeCheckBox({super.key, required this.rememberMeCheckBox});

  final ValueNotifier<bool> rememberMeCheckBox;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: rememberMeCheckBox,
      builder: (context, value, child) {
        return Checkbox(
          value: value,
          activeColor: LoginStyles.primaryColor,
          side: const BorderSide(color: LoginStyles.hintColor),
          onChanged: (value) {
            rememberMeCheckBox.value = value ?? false;
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          visualDensity: VisualDensity.compact,
        );
      },
    );
  }
}
