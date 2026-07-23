import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/core/widgets/app_snack_bar.dart';
import 'package:cinmovies_app/features/home/presentation/data/home_mock_data.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';
import 'package:cinmovies_app/features/movie_details/presentation/cubit/movie_details_cubit.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_backdrop.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_info.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_tab_content.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_tabs.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/similar_movies_section.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/trailer_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MovieDetailsScreen extends StatelessWidget {
  const MovieDetailsScreen({super.key, required this.movie});

  final HomeMovieModel movie;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MovieDetailsCubit(sl<LibraryRepository>(), movie)
        ..loadSavedState(),
      child: _MovieDetailsView(movie: movie),
    );
  }
}

class _MovieDetailsView extends StatelessWidget {
  const _MovieDetailsView({required this.movie});

  final HomeMovieModel movie;

  List<HomeMovieModel> get _similarMovies {
    return kHomeMovies.where((candidate) {
      if (candidate.id == movie.id) return false;
      return candidate.genres.any(movie.genres.contains);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MovieDetailsCubit, MovieDetailsState>(
      builder: (context, state) {
        final cubit = context.read<MovieDetailsCubit>();

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: MovieDetailsBackdrop(
                      movie: movie,
                      isFavorite: state.isFavorite,
                      onBackPressed: Navigator.of(context).pop,
                      onFavoritePressed: () => _toggleFavorite(context),
                      onSharePressed: _shareMovie,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: MovieDetailsInfo(
                      movie: movie,
                      inWatchlist: state.inWatchlist,
                      onTrailerPressed: cubit.showTrailer,
                      onWatchlistPressed: () => _toggleWatchlist(context),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: MovieDetailsTabs(
                      activeTab: state.activeTab,
                      onTabSelected: cubit.selectTab,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: MovieDetailsTabContent(
                      activeTab: state.activeTab,
                      movie: movie,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SimilarMoviesSection(
                      movies: _similarMovies,
                      onMoviePressed: (movie) => _openSimilarMovie(
                        context,
                        movie,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 30)),
                ],
              ),
              if (state.showTrailer)
                TrailerOverlay(movie: movie, onClose: cubit.hideTrailer),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    final success = await context.read<MovieDetailsCubit>().toggleFavorite();
    if (!success && context.mounted) {
      AppSnackBar.showInfo(context, 'Sign in to update your favorite movies.');
    }
  }

  Future<void> _toggleWatchlist(BuildContext context) async {
    final success = await context.read<MovieDetailsCubit>().toggleWatchlist();
    if (!success && context.mounted) {
      AppSnackBar.showInfo(context, 'Sign in to update your watchlist.');
    }
  }

  void _openSimilarMovie(BuildContext context, HomeMovieModel movie) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MovieDetailsScreen(movie: movie)),
    );
  }

  void _shareMovie() {}
}
