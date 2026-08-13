import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';
import 'package:cinmovies_app/features/library/domain/entities/library_movie_entry.dart';
import 'package:cinmovies_app/features/library/presentation/cubit/library_cubit.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/trailers/data/trailer_history_repository.dart';
import 'package:cinmovies_app/features/trailers/domain/entities/trailer_history_entry.dart';
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

  test(
    'loadNextPage appends older page and stops when page is short',
    () async {
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
      expect(
        repository.requests.where((request) => request == 'favorite:1:20'),
        ['favorite:1:20'],
      );
    },
  );
}

class _FakeTrailerHistoryRepository implements TrailerHistoryRepository {
  @override
  Future<Result<TrailerHistoryEntry?>> findByVideoKey(String videoKey) async {
    return const Success(null);
  }

  @override
  Future<Result<List<TrailerHistoryEntry>>> history() async {
    return const Success([]);
  }

  @override
  Future<Result<void>> saveProgress(TrailerHistoryEntry entry) async {
    return const Success(null);
  }

  @override
  Future<Result<void>> remove(String videoKey) async {
    return const Success(null);
  }

  @override
  Stream<List<TrailerHistoryEntry>> watchHistory() {
    return Stream.value(const []);
  }
}

class _FakeLibraryRepository implements LibraryRepository {
  _FakeLibraryRepository(this.pages);

  final Map<String, List<LibraryMovieEntry>> pages;
  final List<String> requests = [];

  @override
  Future<Result<List<LibraryMovieEntry>>> movieEntriesPage({
    required UserMovieListType type,
    required int page,
    required int pageSize,
  }) async {
    requests.add('${type.value}:$page:$pageSize');
    return Success(pages['${type.value}:$page'] ?? const []);
  }

  @override
  Future<Result<void>> removeMovieIdFromList({
    required String movieId,
    required UserMovieListType type,
  }) async {
    return const Success(null);
  }

  @override
  Future<Result<bool>> contains(Movie movie, UserMovieListType type) async {
    return const Success(false);
  }

  @override
  Future<Result<int>> count(UserMovieListType type) async {
    return const Success(0);
  }

  @override
  Future<Result<List<LibraryMovieEntry>>> movieEntries(
    UserMovieListType type,
  ) async {
    return movieEntriesPage(
      type: type,
      page: 0,
      pageSize: LibraryCubit.pageSize,
    );
  }

  @override
  Future<Result<List<Movie>>> movies(UserMovieListType type) async {
    return const Success([]);
  }

  @override
  Future<Result<void>> setListed(
    Movie movie,
    UserMovieListType type, {
    required bool listed,
  }) async {
    return const Success(null);
  }
}

LibraryMovieEntry _row(String id, String title) {
  return LibraryMovieEntry(
    storedMovieId: id,
    movie: Movie(
      id: '${int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1}',
      title: title,
      imageAsset: 'assets/images/movie_ex1.jpg',
      genres: const [],
      rating: 7,
      year: '2026',
      duration: '2h',
      ageRating: 'NR',
      synopsis: 'Synopsis',
      director: 'Unknown',
      votes: '1K',
      cast: const [],
      reviews: const [],
    ),
  );
}
