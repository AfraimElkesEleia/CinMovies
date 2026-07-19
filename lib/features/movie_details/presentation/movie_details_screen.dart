import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/home/presentation/data/home_mock_data.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:cinmovies_app/features/movie_details/presentation/model/movie_details_tab.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_backdrop.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_info.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_tab_content.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_tabs.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/similar_movies_section.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/trailer_overlay.dart';
import 'package:flutter/material.dart';

class MovieDetailsScreen extends StatefulWidget {
  const MovieDetailsScreen({super.key, required this.movie});

  final HomeMovieModel movie;

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  MovieDetailsTab _activeTab = MovieDetailsTab.overview;
  bool _isFavorite = false;
  bool _inWatchlist = false;
  bool _showTrailer = false;

  List<HomeMovieModel> get _similarMovies {
    return kHomeMovies.where((movie) {
      if (movie.id == widget.movie.id) return false;
      return movie.genres.any(widget.movie.genres.contains);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: MovieDetailsBackdrop(
                  movie: widget.movie,
                  isFavorite: _isFavorite,
                  onBackPressed: Navigator.of(context).pop,
                  onFavoritePressed: _toggleFavorite,
                  onSharePressed: _shareMovie,
                ),
              ),
              SliverToBoxAdapter(
                child: MovieDetailsInfo(
                  movie: widget.movie,
                  inWatchlist: _inWatchlist,
                  onTrailerPressed: _showTrailerOverlay,
                  onWatchlistPressed: _toggleWatchlist,
                ),
              ),
              SliverToBoxAdapter(
                child: MovieDetailsTabs(
                  activeTab: _activeTab,
                  onTabSelected: _selectTab,
                ),
              ),
              SliverToBoxAdapter(
                child: MovieDetailsTabContent(
                  activeTab: _activeTab,
                  movie: widget.movie,
                ),
              ),
              SliverToBoxAdapter(
                child: SimilarMoviesSection(
                  movies: _similarMovies,
                  onMoviePressed: _openSimilarMovie,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
          if (_showTrailer)
            TrailerOverlay(movie: widget.movie, onClose: _hideTrailerOverlay),
        ],
      ),
    );
  }

  void _selectTab(MovieDetailsTab tab) {
    setState(() {
      _activeTab = tab;
    });
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _toggleWatchlist() {
    setState(() {
      _inWatchlist = !_inWatchlist;
    });
  }

  void _showTrailerOverlay() {
    setState(() {
      _showTrailer = true;
    });
  }

  void _hideTrailerOverlay() {
    setState(() {
      _showTrailer = false;
    });
  }

  void _openSimilarMovie(HomeMovieModel movie) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MovieDetailsScreen(movie: movie)),
    );
  }

  void _shareMovie() {}
}
