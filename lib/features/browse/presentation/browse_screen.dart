import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/browse/presentation/cubit/browse_cubit.dart';
import 'package:cinmovies_app/features/browse/presentation/widgets/browse_search_bar.dart';
import 'package:cinmovies_app/features/home/presentation/widgets/movie_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BrowseCubit(),
      child: BlocBuilder<BrowseCubit, BrowseState>(
        builder: (context, state) {
          final filteredMovies = state.filteredMovies;

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
                              itemCount: BrowseState.genres.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final genre = BrowseState.genres[index];
                                final isActive = genre == state.activeGenre;

                                return ChoiceChip(
                                  label: Text(genre),
                                  selected: isActive,
                                  onSelected: (_) {
                                    context.read<BrowseCubit>().setGenre(genre);
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
                                '${filteredMovies.length} movies',
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
                      itemCount: filteredMovies.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.72,
                      ),
                      itemBuilder: (context, index) {
                        final movie = filteredMovies[index];
                        return MovieCard(
                          movie: movie,
                          onTap: () {
                            context.pushNamed(
                              Routes.movieDetails,
                              arguments: movie,
                            );
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
        },
      ),
    );
  }
}
