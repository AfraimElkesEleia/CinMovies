import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/browse/presentation/widgets/browse_search_bar.dart';
import 'package:cinmovies_app/features/home/presentation/data/home_mock_data.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/movie_card.dart';
import 'package:flutter/material.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  static const List<String> _genres = [
    'All',
    'Action',
    'Adventure',
    'Hero',
    'Sci-Fi',
    'Drama',
  ];

  String _activeGenre = 'All';

  List<HomeMovieModel> get _filteredMovies {
    if (_activeGenre == 'All') return kHomeMovies;

    return kHomeMovies.where((movie) {
      return movie.genres.contains(_activeGenre);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Browse Movies',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    BrowseSearchBar(
                      onTap: () => context.pushNamed(Routes.search),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _genres.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final genre = _genres[index];
                          final isActive = genre == _activeGenre;

                          return ChoiceChip(
                            label: Text(genre),
                            selected: isActive,
                            onSelected: (_) {
                              setState(() {
                                _activeGenre = genre;
                              });
                            },
                            showCheckmark: false,
                            selectedColor: AppColors.loginPrimary,
                            backgroundColor: AppColors.surface,
                            side: BorderSide(
                              color: isActive
                                  ? AppColors.loginPrimary
                                  : AppColors.surfaceBorder,
                            ),
                            labelStyle: TextStyle(
                              color: isActive
                                  ? AppColors.white
                                  : AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          '${_filteredMovies.length} movies',
                          style: const TextStyle(
                            color: AppColors.iconMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.sort_rounded,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Popularity',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid.builder(
                itemCount: _filteredMovies.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (context, index) {
                  final movie = _filteredMovies[index];
                  return MovieCard(
                    movie: movie,
                    onTap: () {
                      context.pushNamed(Routes.movieDetails, arguments: movie);
                    },
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }
}
