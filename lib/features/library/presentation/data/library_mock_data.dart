import 'package:cinmovies_app/features/library/presentation/model/library_movie_model.dart';
import 'package:cinmovies_app/features/library/presentation/model/library_tab_model.dart';
import 'package:flutter/material.dart';

class LibraryMockData {
  const LibraryMockData._();

  static const List<LibraryTabModel> tabs = [
    LibraryTabModel(
      label: 'History',
      emptyLabel: 'No watch history yet',
      movies: [
        LibraryMovieModel(
          title: 'Avengers: Doomsday',
          imageAsset: 'assets/images/movie_ex1.jpg',
          genre: 'Action, Sci-Fi',
          year: '2026',
          duration: '2h 28m',
          status: 'Continue watching',
          progress: 0.72,
          actionIcon: Icons.play_arrow_rounded,
        ),
        LibraryMovieModel(
          title: 'Spider-Man: Brand New Day',
          imageAsset: 'assets/images/movie_ex2.jpg',
          genre: 'Adventure, Hero',
          year: '2026',
          duration: '2h 12m',
          status: 'Last watched today',
          progress: 0.38,
          actionIcon: Icons.play_arrow_rounded,
        ),
      ],
    ),
    LibraryTabModel(
      label: 'Watchlist',
      emptyLabel: 'Your watchlist is empty',
      movies: [
        LibraryMovieModel(
          title: 'Spider-Man: Brand New Day',
          imageAsset: 'assets/images/movie_ex2.jpg',
          genre: 'Adventure, Hero',
          year: '2026',
          duration: '2h 12m',
          status: 'Saved for later',
          progress: 0,
          actionIcon: Icons.bookmark_rounded,
        ),
        LibraryMovieModel(
          title: 'Avengers: Doomsday',
          imageAsset: 'assets/images/movie_ex1.jpg',
          genre: 'Action, Sci-Fi',
          year: '2026',
          duration: '2h 28m',
          status: 'Premiere reminder',
          progress: 0,
          actionIcon: Icons.notifications_active_rounded,
        ),
      ],
    ),
    LibraryTabModel(
      label: 'Favorites',
      emptyLabel: 'No favorite movies yet',
      movies: [
        LibraryMovieModel(
          title: 'Avengers: Doomsday',
          imageAsset: 'assets/images/movie_ex1.jpg',
          genre: 'Action, Sci-Fi',
          year: '2026',
          duration: '2h 28m',
          status: 'Rated 8.7',
          progress: 1,
          actionIcon: Icons.favorite_rounded,
        ),
      ],
    ),
    LibraryTabModel(
      label: 'Downloaded',
      emptyLabel: 'No downloads available',
      movies: [
        LibraryMovieModel(
          title: 'Spider-Man: Brand New Day',
          imageAsset: 'assets/images/movie_ex2.jpg',
          genre: 'Adventure, Hero',
          year: '2026',
          duration: '2h 12m',
          status: 'Downloaded',
          progress: 1,
          actionIcon: Icons.download_done_rounded,
        ),
        LibraryMovieModel(
          title: 'Avengers: Doomsday',
          imageAsset: 'assets/images/movie_ex1.jpg',
          genre: 'Action, Sci-Fi',
          year: '2026',
          duration: '2h 28m',
          status: 'Downloading',
          progress: 0.46,
          actionIcon: Icons.downloading_rounded,
        ),
      ],
    ),
  ];
}
