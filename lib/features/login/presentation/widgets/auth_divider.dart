import 'package:flutter/material.dart';

import 'login_styles.dart';

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final dividerColor = LoginStyles.textColor.withValues(alpha: 0.5);

    return Row(
      children: [
        Expanded(
          child: Divider(color: dividerColor, thickness: 1, height: 32),
        ),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: dividerColor)),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(color: dividerColor, thickness: 1, height: 32),
        ),
      ],
    );
  }
}
