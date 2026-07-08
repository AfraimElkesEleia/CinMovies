import 'package:flutter/material.dart';

extension NavigationExtension on BuildContext {
  Future<dynamic> pushNamed(String route, {Object? arguments}) {
    return Navigator.pushNamed(this, route, arguments: arguments);
  }

  Future<dynamic> pushReplacementNamed(String route, {Object? arguments}) {
    return Navigator.pushReplacementNamed(this, route, arguments: arguments);
  }

  Future<dynamic> pushNamedAndRemoveUntil(String route, {Object? arguments}) {
    return Navigator.pushNamedAndRemoveUntil(
      this,
      route,
      (route) => false,
      arguments: arguments,
    );
  }

  void pop() {
    Navigator.pop(this);
  }
}
