import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';
import 'package:cinmovies_app/features/library/presentation/cubit/library_cubit.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/trailers/data/trailer_history_repository.dart';
import 'package:cinmovies_app/features/trailers/domain/entities/trailer_history_entry.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('load fetches first page for every tab newest first', () async {
    final repository = _FakeLibraryRepository({
      'watchlist:0': [
        _row('newer', 'Newer Movie'),
        _row('older', 'Older Movie'),
      ],
    });
    final cubit = LibraryCubit(repository, _FakeTrailerHistoryRepository());
    addTearDown(cubit.close);

    await cubit.load();

    final watchlist = cubit.state.tabs.firstWhere(
      (tab) => tab.type == UserMovieListType.watchlist.value,
    );
    expect(watchlist.movies.map((movie) => movie.title), [
      'Newer Movie',
      'Older Movie',
    ]);
    expect(repository.requests, contains('watchlist:0:20'));
    expect(repository.requests, contains('favorite:0:20'));
    expect(
      repository.requests.any((request) => request.startsWith('watched:')),
      isFalse,
    );
  });

  test('loadNextPage appends older page and stops when page is short', () async {
    final firstPage = List.generate(
      LibraryCubit.pageSize,
      (index) => _row('movie-$index', 'Movie $index'),
    );
    final repository = _FakeLibraryRepository({
      'favorite:0': firstPage,
      'favorite:1': [_row('older', 'Older Movie')],
    });
    final cubit = LibraryCubit(repository, _FakeTrailerHistoryRepository());
    addTearDown(cubit.close);

    await cubit.load();
    await cubit.loadNextPage(UserMovieListType.favorite.value);
    await cubit.loadNextPage(UserMovieListType.favorite.value);

    final favorites = cubit.state.tabs.firstWhere(
      (tab) => tab.type == UserMovieListType.favorite.value,
    );
    expect(favorites.movies.length, LibraryCubit.pageSize + 1);
    expect(favorites.movies.last.title, 'Older Movie');
    expect(favorites.hasMore, isFalse);
    expect(repository.requests.where((request) => request == 'favorite:1:20'), [
      'favorite:1:20',
    ]);
  });
}

class _FakeTrailerHistoryRepository
    implements TrailerHistoryRepositoryContract {
  @override
  Future<Either<Failure, TrailerHistoryEntry?>> findByVideoKey(
    String videoKey,
  ) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<TrailerHistoryEntry>>> history() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, void>> saveProgress(
    TrailerHistoryEntry entry,
  ) async {
    return const Right(null);
  }

  @override
  Stream<List<TrailerHistoryEntry>> watchHistory() {
    return Stream.value(const []);
  }
}

class _FakeLibraryRepository implements LibraryRepositoryContract {
  _FakeLibraryRepository(this.pages);

  final Map<String, List<Map<String, dynamic>>> pages;
  final List<String> requests = [];

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> movieRowsPage({
    required UserMovieListType type,
    required int page,
    required int pageSize,
  }) async {
    requests.add('${type.value}:$page:$pageSize');
    return Right(pages['${type.value}:$page'] ?? const []);
  }

  @override
  Future<Either<Failure, void>> removeMovieIdFromList({
    required String movieId,
    required UserMovieListType type,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> contains(
    Movie movie,
    UserMovieListType type,
  ) async {
    return const Right(false);
  }

  @override
  Future<Either<Failure, int>> count(UserMovieListType type) async {
    return const Right(0);
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> movieRows(
    UserMovieListType type,
  ) async {
    return movieRowsPage(
      type: type,
      page: 0,
      pageSize: LibraryCubit.pageSize,
    );
  }

  @override
  Future<Either<Failure, List<Movie>>> movies(UserMovieListType type) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, void>> setListed(
    Movie movie,
    UserMovieListType type, {
    required bool listed,
  }) async {
    return const Right(null);
  }
}

Map<String, dynamic> _row(String id, String title) {
  return {
    'id': id,
    'tmdb_id': int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1,
    'title': title,
    'poster_path': 'assets/images/movie_ex1.jpg',
    'release_date': '2026-01-01',
    'runtime_minutes': 120,
    'vote_average': 7.0,
    'vote_count': 1000,
    'overview': 'Synopsis',
    'age_rating': 'NR',
  };
}
