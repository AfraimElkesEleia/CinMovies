import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:cinmovies_app/features/movie_details/presentation/model/movie_details_tab.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_cast_tab.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_overview_tab.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_reviews_tab.dart';
import 'package:flutter/material.dart';

class MovieDetailsTabContent extends StatelessWidget {
  const MovieDetailsTabContent({
    super.key,
    required this.activeTab,
    required this.movie,
  });

  final MovieDetailsTab activeTab;
  final HomeMovieModel movie;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: switch (activeTab) {
        MovieDetailsTab.overview => MovieDetailsOverviewTab(movie: movie),
        MovieDetailsTab.cast => MovieDetailsCastTab(cast: movie.cast),
        MovieDetailsTab.reviews => MovieDetailsReviewsTab(
          reviews: movie.reviews,
        ),
      },
    );
  }
}
