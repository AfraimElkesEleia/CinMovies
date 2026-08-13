import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/features/login/presentation/login_screen.dart';
import 'package:cinmovies_app/features/main/presentation/main_navigation_screen.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/movie_details/presentation/model/movie_details_args.dart';
import 'package:cinmovies_app/features/movie_details/presentation/movie_details_screen.dart';
import 'package:cinmovies_app/features/home/presentation/model/movie_section_args.dart';
import 'package:cinmovies_app/features/home/presentation/movie_section_screen.dart';
import 'package:cinmovies_app/features/onboarding/onboarding_screen.dart';
import 'package:cinmovies_app/features/onboarding/onboarding_genre_preferences_screen.dart';
import 'package:cinmovies_app/features/profile/presentation/edit_profile_screen.dart';
import 'package:cinmovies_app/features/profile/presentation/favorite_genres_screen.dart';
import 'package:cinmovies_app/features/profile/presentation/my_reviews_screen.dart';
import 'package:cinmovies_app/features/reviews/presentation/model/review_replies_args.dart';
import 'package:cinmovies_app/features/reviews/presentation/review_replies_screen.dart';
import 'package:cinmovies_app/features/search/presentation/search_screen.dart';
import 'package:cinmovies_app/features/signup/presentation/signup_screen.dart';
import 'package:cinmovies_app/features/trailers/presentation/model/trailer_viewer_args.dart';
import 'package:cinmovies_app/features/trailers/presentation/trailer_viewer_screen.dart';
import 'package:flutter/material.dart';

class AppRouter {
  const AppRouter();

  Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
      case AppRoutes.search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case AppRoutes.movieSection:
        final args = settings.arguments;
        if (args is MovieSectionArgs) {
          return MaterialPageRoute(
            builder: (_) => MovieSectionScreen(args: args),
          );
        }
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
      case AppRoutes.movieDetails:
        final args = settings.arguments;
        if (args is MovieDetailsArgs) {
          return MaterialPageRoute(
            builder: (_) =>
                MovieDetailsScreen(movie: args.movie, heroTag: args.heroTag),
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
      case AppRoutes.trailerViewer:
        final args = settings.arguments;
        if (args is TrailerViewerArgs) {
          return MaterialPageRoute(
            builder: (_) => TrailerViewerScreen(args: args),
          );
        }
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case AppRoutes.preferenceOnboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingGenrePreferencesScreen(),
        );
      case AppRoutes.editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case AppRoutes.favoriteGenres:
        return MaterialPageRoute(builder: (_) => const FavoriteGenresScreen());
      case AppRoutes.myReviews:
        return MaterialPageRoute(builder: (_) => const MyReviewsScreen());
      case AppRoutes.reviewReplies:
        final args = settings.arguments;
        if (args is ReviewRepliesArgs) {
          return MaterialPageRoute(
            builder: (_) => ReviewRepliesScreen(review: args.review),
          );
        }
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
    }

    return null;
  }
}
