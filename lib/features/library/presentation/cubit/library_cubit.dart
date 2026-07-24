import 'package:cinmovies_app/features/library/data/library_repository.dart';
import 'package:cinmovies_app/features/library/presentation/model/library_movie_model.dart';
import 'package:cinmovies_app/features/library/presentation/model/library_tab_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum LibraryStatus { initial, loading, loaded, failure }

class LibraryState extends Equatable {
  const LibraryState({
    this.status = LibraryStatus.initial,
    this.tabs = _emptyTabs,
  });

  static const _emptyTabs = [
    LibraryTabModel(
      label: 'History',
      emptyLabel: 'No watch history yet',
      movies: [],
    ),
    LibraryTabModel(
      label: 'Watchlist',
      emptyLabel: 'Your watchlist is empty',
      movies: [],
    ),
    LibraryTabModel(
      label: 'Favorites',
      emptyLabel: 'No favorite movies yet',
      movies: [],
    ),
    LibraryTabModel(
      label: 'Downloaded',
      emptyLabel: 'No downloads available',
      movies: [],
    ),
  ];

  final LibraryStatus status;
  final List<LibraryTabModel> tabs;

  @override
  List<Object> get props => [status, tabs];
}

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(this._repository) : super(const LibraryState());

  final LibraryRepository _repository;

  Future<void> load() async {
    emit(const LibraryState(status: LibraryStatus.loading));
    try {
      final results = await Future.wait([
        _repository.movieRows(UserMovieListType.watched),
        _repository.movieRows(UserMovieListType.watchlist),
        _repository.movieRows(UserMovieListType.favorite),
        _repository.movieRows(UserMovieListType.downloaded),
      ]);

      // If any tab returned a failure, emit the failure state.
      for (final result in results) {
        if (result.isLeft()) {
          emit(const LibraryState(status: LibraryStatus.failure));
          return;
        }
      }

      emit(
        LibraryState(
          status: LibraryStatus.loaded,
          tabs: _buildTabsFromRows(
            results.map((e) => e.getOrElse(() => [])).toList(),
          ),
        ),
      );
    } catch (_) {
      emit(const LibraryState(status: LibraryStatus.failure));
    }
  }

  List<LibraryTabModel> _buildTabsFromRows(
    List<List<Map<String, dynamic>>> rows,
  ) {
    return [
      LibraryTabModel(
        label: 'History',
        emptyLabel: 'No watch history yet',
        movies: rows[0]
            .map((row) => _movieFromRow(row, 'Continue watching', 1))
            .toList(),
      ),
      LibraryTabModel(
        label: 'Watchlist',
        emptyLabel: 'Your watchlist is empty',
        movies: rows[1]
            .map((row) => _movieFromRow(row, 'Saved for later', 0))
            .toList(),
      ),
      LibraryTabModel(
        label: 'Favorites',
        emptyLabel: 'No favorite movies yet',
        movies: rows[2]
            .map((row) => _movieFromRow(row, 'Favorite', 1))
            .toList(),
      ),
      LibraryTabModel(
        label: 'Downloaded',
        emptyLabel: 'No downloads available',
        movies: rows[3]
            .map((row) => _movieFromRow(row, 'Downloaded', 1))
            .toList(),
      ),
    ];
  }

  LibraryMovieModel _movieFromRow(
    Map<String, dynamic> row,
    String status,
    double progress,
  ) {
    return LibraryMovieModel(
      title: row['title'] as String? ?? 'Untitled',
      imageAsset:
          row['poster_path'] as String? ?? 'assets/images/movie_ex1.jpg',
      genre: 'Movie',
      year: ((row['release_date'] as String?) ?? '').split('-').first,
      duration: _duration(row['runtime_minutes'] as int?),
      status: status,
      progress: progress,
      actionIcon: _iconForStatus(status),
    );
  }

  String _duration(int? minutes) {
    if (minutes == null || minutes <= 0) return 'Unknown';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) return '${remainingMinutes}m';
    return '${hours}h ${remainingMinutes}m';
  }

  IconData _iconForStatus(String status) {
    return switch (status) {
      'Saved for later' => Icons.bookmark_rounded,
      'Favorite' => Icons.favorite_rounded,
      'Downloaded' => Icons.download_done_rounded,
      _ => Icons.play_arrow_rounded,
    };
  }
}
