import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/features/login/presentation/login_screen.dart';
import 'package:cinmovies_app/features/main/presentation/main_navigation_screen.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:cinmovies_app/features/movie_details/presentation/movie_details_screen.dart';
import 'package:cinmovies_app/features/onboarding_screen/onboarding_pageview.dart';
import 'package:cinmovies_app/features/onboarding_screen/preference_onboarding_screen.dart';
import 'package:cinmovies_app/features/search/presentation/search_screen.dart';
import 'package:cinmovies_app/features/signup/presentation/signup_screen.dart';
import 'package:flutter/material.dart';

class AppRouter {
  const AppRouter();

  Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.onBoarding:
        return MaterialPageRoute(builder: (_) => const OnBoardingPageview());
      case Routes.home:
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
      case Routes.search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case Routes.movieDetails:
        final movie = settings.arguments;
        if (movie is HomeMovieModel) {
          return MaterialPageRoute(
            builder: (_) => MovieDetailsScreen(movie: movie),
          );
        }
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
      case Routes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case Routes.register:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case Routes.preferenceOnboarding:
        return MaterialPageRoute(
          builder: (_) => const PreferenceOnboardingScreen(),
        );
    }

    return null;
  }
}
