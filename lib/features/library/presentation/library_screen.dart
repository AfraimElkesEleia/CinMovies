import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/core/widgets/app_snack_bar.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';
import 'package:cinmovies_app/features/library/presentation/cubit/library_cubit.dart';
import 'package:cinmovies_app/features/movie_details/data/model/movie_details_args.dart';
import 'package:cinmovies_app/features/library/presentation/widgets/library_header.dart';
import 'package:cinmovies_app/features/library/presentation/widgets/library_movie_list.dart';
import 'package:cinmovies_app/features/library/presentation/widgets/library_tab_bar.dart';
import 'package:cinmovies_app/features/trailers/data/trailer_history_repository.dart';
import 'package:cinmovies_app/features/trailers/domain/entities/trailer_history_entry.dart';
import 'package:cinmovies_app/features/trailers/presentation/model/trailer_viewer_args.dart';
import 'package:cinmovies_app/features/library/presentation/widgets/trailer_history_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LibraryCubit(
        sl<LibraryRepository>(),
        sl<TrailerHistoryRepository>(),
      )..load(),
      child: BlocBuilder<LibraryCubit, LibraryState>(
        builder: (context, state) {
          final tabs = state.tabs;

          return DefaultTabController(
            length: tabs.length,
            child: Scaffold(
              backgroundColor: AppColors.scaffoldBackground,
              body: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LibraryHeader(),
                    const SizedBox(height: 18),
                    LibraryTabBar(tabs: tabs),
                    const SizedBox(height: 14),
                    Expanded(
                      child: TabBarView(
                        children: tabs
                            .map(
                              (tab) => RefreshIndicator(
                                color: AppColors.loginPrimary,
                                backgroundColor: AppColors.surface,
                                onRefresh: context.read<LibraryCubit>().load,
                                child: tab.type == 'trailer_history'
                                    ? TrailerHistoryList(
                                        entries: state.history,
                                        emptyLabel: tab.emptyLabel,
                                        onPressed: (entry) =>
                                            _openTrailer(context, entry),
                                        onRemovePressed: (entry) =>
                                            _removeHistoryEntry(context, entry),
                                      )
                                    : LibraryMovieList(
                                        movies: tab.movies,
                                        emptyLabel: tab.emptyLabel,
                                        isLoadingMore: tab.isLoadingMore,
                                        hasMore: tab.hasMore,
                                        onLoadMore: () => context
                                            .read<LibraryCubit>()
                                            .loadNextPage(tab.type),
                                        onMoviePressed: (movie, heroTag) {
                                          context.pushNamed(
                                            Routes.movieDetails,
                                            arguments: MovieDetailsArgs(
                                              movie: movie.movie,
                                              heroTag: heroTag,
                                            ),
                                          );
                                        },
                                        onRemovePressed: (movie) => context
                                            .read<LibraryCubit>()
                                            .removeFromList(movie, tab.type),
                                      ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openTrailer(BuildContext context, TrailerHistoryEntry entry) {
    context.pushNamed(
      Routes.trailerViewer,
      arguments: TrailerViewerArgs(
        videoKey: entry.videoKey,
        movieId: entry.movieId,
        title: entry.title,
        imageAsset: entry.imageAsset,
      ),
    );
  }

  Future<void> _removeHistoryEntry(
    BuildContext context,
    TrailerHistoryEntry entry,
  ) async {
    final removed = await context
        .read<LibraryCubit>()
        .removeFromHistory(entry);
    if (!context.mounted) return;

    if (removed) {
      AppSnackBar.showSuccess(context, 'Removed from history.');
    } else {
      AppSnackBar.showError(context, 'Could not remove from history.');
    }
  }
}
