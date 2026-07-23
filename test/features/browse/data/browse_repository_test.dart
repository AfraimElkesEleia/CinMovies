import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cinmovies_app/features/browse/data/browse_genre.dart';
import 'package:cinmovies_app/features/browse/data/browse_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeAdapter adapter;
  late BrowseRepository repository;

  setUp(() {
    dotenv.loadFromString(envString: 'TMDB_API_KEY=test-token');
    adapter = _FakeAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.themoviedb.org/3'))
      ..httpClientAdapter = adapter;
    repository = BrowseRepository(dio);
  });

  test('fetchGenres parses TMDB genres and adds All first', () async {
    adapter.responseJson = {
      'genres': [
        {'id': 28, 'name': 'Action'},
        {'id': 18, 'name': 'Drama'},
      ],
    };

    final result = await repository.fetchGenres();

    expect(result.isRight(), isTrue);
    final genres = result.getOrElse(() => const []);
    expect(genres, [
      BrowseGenre.all,
      const BrowseGenre(id: 28, name: 'Action'),
      const BrowseGenre(id: 18, name: 'Drama'),
    ]);
    expect(adapter.lastOptions?.path, '/genre/movie/list');
    expect(
      adapter.lastOptions?.headers['Authorization'],
      'Bearer test-token',
    );
  });

  test('fetchMovies omits with_genres for All', () async {
    adapter.responseJson = {
      'page': 1,
      'total_pages': 3,
      'results': [
        {'id': 10, 'title': 'Popular Movie'},
      ],
    };

    final result = await repository.fetchMovies(page: 1);

    expect(result.isRight(), isTrue);
    final page = result.getOrElse(
      () => const BrowseMoviesPage(movies: [], page: 0, totalPages: 0),
    );
    expect(page.movies.single.title, 'Popular Movie');
    expect(page.page, 1);
    expect(page.totalPages, 3);
    expect(adapter.lastOptions?.path, '/discover/movie');
    expect(adapter.lastOptions?.queryParameters['sort_by'], 'popularity.desc');
    expect(adapter.lastOptions?.queryParameters.containsKey('with_genres'), isFalse);
  });

  test('fetchMovies includes with_genres for selected TMDB genre', () async {
    adapter.responseJson = {
      'page': 2,
      'total_pages': 4,
      'results': const [],
    };

    await repository.fetchMovies(
      page: 2,
      genre: const BrowseGenre(id: 878, name: 'Science Fiction'),
    );

    expect(adapter.lastOptions?.queryParameters['page'], 2);
    expect(adapter.lastOptions?.queryParameters['with_genres'], 878);
  });
}

class _FakeAdapter implements HttpClientAdapter {
  Map<String, Object?> responseJson = const {};
  RequestOptions? lastOptions;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody.fromString(
      jsonEncode(responseJson),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
