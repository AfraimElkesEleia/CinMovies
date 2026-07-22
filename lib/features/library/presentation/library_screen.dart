import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';
import 'package:cinmovies_app/features/library/presentation/cubit/library_cubit.dart';
import 'package:cinmovies_app/features/library/presentation/widgets/library_header.dart';
import 'package:cinmovies_app/features/library/presentation/widgets/library_movie_list.dart';
import 'package:cinmovies_app/features/library/presentation/widgets/library_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LibraryCubit(sl<LibraryRepository>())..load(),
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
                              (tab) => LibraryMovieList(
                                movies: tab.movies,
                                emptyLabel: tab.emptyLabel,
                                showDownloadActions: tab.label == 'Downloaded',
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
}
