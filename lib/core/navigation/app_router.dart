import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/features/login/presentation/login_screen.dart';
import 'package:cinmovies_app/features/main/presentation/main_navigation_screen.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/movie_details/data/model/movie_details_args.dart';
import 'package:cinmovies_app/features/movie_details/presentation/movie_details_screen.dart';
import 'package:cinmovies_app/features/home/data/model/movie_section_args.dart';
import 'package:cinmovies_app/features/home/presentation/movie_section_screen.dart';
import 'package:cinmovies_app/features/onboarding_screen/onboarding_pageview.dart';
import 'package:cinmovies_app/features/onboarding_screen/preference_onboarding_screen.dart';
import 'package:cinmovies_app/features/profile/presentation/edit_profile_screen.dart';
import 'package:cinmovies_app/features/profile/presentation/favorite_genres_screen.dart';
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
      case Routes.movieSection:
        final args = settings.arguments;
        if (args is MovieSectionArgs) {
          return MaterialPageRoute(
            builder: (_) => MovieSectionScreen(args: args),
          );
        }
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
      case Routes.movieDetails:
        final args = settings.arguments;
        if (args is MovieDetailsArgs) {
          return MaterialPageRoute(
            builder: (_) => MovieDetailsScreen(
              movie: args.movie,
              heroTag: args.heroTag,
            ),
          );
        }
        if (args is Movie) {
          return MaterialPageRoute(
            builder: (_) => MovieDetailsScreen(
              movie: args,
              heroTag: 'movie-poster-${args.id}',
            ),
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
      case Routes.editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case Routes.favoriteGenres:
        return MaterialPageRoute(builder: (_) => const FavoriteGenresScreen());
    }

    return null;
  }
}
