import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:cinmovies_app/features/search/presentation/model/search_category_model.dart';
import 'package:flutter/material.dart';

class SearchMockData {
  const SearchMockData._();

  static const List<HomeMovieModel> movies = [
    HomeMovieModel(
      title: 'Avengers: Doomsday',
      imageAsset: 'assets/images/movie_ex1.jpg',
      genres: ['Action', 'Sci-Fi'],
      rating: 8.7,
      year: '2026',
    ),
    HomeMovieModel(
      title: 'Spider-Man: Brand New Day',
      imageAsset: 'assets/images/movie_ex2.jpg',
      genres: ['Adventure', 'Hero'],
      rating: 8.5,
      year: '2026',
    ),
  ];

  static const List<String> recentSearches = [
    'Avengers',
    'Spider-Man',
    'Action',
    'Sci-Fi',
  ];

  static const List<String> popularSearches = [
    'Marvel',
    'Hero',
    'Adventure',
    '2026',
  ];

  static const List<SearchCategoryModel> categories = [
    SearchCategoryModel(
      label: 'Action',
      icon: Icons.flash_on_rounded,
      color: AppColors.loginPrimary,
    ),
    SearchCategoryModel(
      label: 'Sci-Fi',
      icon: Icons.rocket_launch_rounded,
      color: AppColors.comingSoonPurple,
    ),
    SearchCategoryModel(
      label: 'Adventure',
      icon: Icons.explore_rounded,
      color: AppColors.ratingAmber,
    ),
    SearchCategoryModel(
      label: 'Drama',
      icon: Icons.theater_comedy_rounded,
      color: AppColors.onboardingPurple,
    ),
  ];
}
