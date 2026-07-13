import 'package:flutter/material.dart';

class LoginStyles {
  const LoginStyles._();

  static const Color surfaceColor = Color(0xFF0F1320);
  static const Color primaryColor = Color(0xFFC8133A);
  static const Color accentColor = Colors.redAccent;
  static const Color textColor = Colors.white;
  static const Color hintColor = Color(0xFF8B93A7);

  static final BorderRadius borderRadius = BorderRadius.circular(16);

  static OutlineInputBorder inputBorder([Color color = Colors.transparent]) {
    return OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: color, width: 0.5),
    );
  }
}
