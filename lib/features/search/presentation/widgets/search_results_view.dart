import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_empty_state.dart';
import 'package:cinmovies_app/features/search/presentation/widgets/search_movie_tile.dart';
import 'package:flutter/material.dart';

class SearchResultsView extends StatelessWidget {
  const SearchResultsView({
    super.key,
    required this.query,
    required this.movies,
  });

  final String query;
  final List<HomeMovieModel> movies;

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return SearchEmptyState(query: query);
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: movies.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            '${movies.length} result${movies.length == 1 ? '' : 's'} for "$query"',
            style: const TextStyle(color: AppColors.iconMuted, fontSize: 13),
          );
        }

        final movie = movies[index - 1];

        return GestureDetector(
          onTap: () {
            context.pushNamed(Routes.movieDetails, arguments: movie);
          },
          child: SearchMovieTile(movie: movie),
        );
      },
    );
  }
}
