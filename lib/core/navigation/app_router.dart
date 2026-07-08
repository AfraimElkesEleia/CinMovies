import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:flutter/material.dart';

class AppRouter {
  const AppRouter();

  Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return MaterialPageRoute(
          builder: (_) => const _RoutePlaceholder(title: 'Splash'),
        );
      case Routes.home:
        return MaterialPageRoute(
          builder: (_) => const _RoutePlaceholder(title: 'Home'),
        );
      case Routes.login:
        return MaterialPageRoute(
          builder: (_) => const _RoutePlaceholder(title: 'Login'),
        );
      case Routes.register:
        return MaterialPageRoute(
          builder: (_) => const _RoutePlaceholder(title: 'Register'),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('No route defined for this path')),
          ),
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
