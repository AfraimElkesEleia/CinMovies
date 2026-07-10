import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/features/login/login_screen.dart';
import 'package:cinmovies_app/features/onboarding_screen/onboarding_pageview.dart';
import 'package:flutter/material.dart';

class AppRouter {
  const AppRouter();

  Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.onBoarding:
        return MaterialPageRoute(builder: (_) => const OnBoardingPageview());
      case Routes.home:
        return MaterialPageRoute(
          builder: (_) => const _RoutePlaceholder(title: 'Home'),
        );
      case Routes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case Routes.register:
        return MaterialPageRoute(
          builder: (_) => const _RoutePlaceholder(title: 'Register'),
        );
    }
  }
}

class _RoutePlaceholder extends StatelessWidget {
  const _RoutePlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(title)));
  }
}
