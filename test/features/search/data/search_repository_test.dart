import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cinmovies_app/features/search/data/search_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeAdapter adapter;
  late SearchRepository repository;

  setUp(() {
    dotenv.loadFromString(envString: 'TMDB_API_KEY=test-token');
    adapter = _FakeAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.themoviedb.org/3'))
      ..httpClientAdapter = adapter;
    repository = SearchRepository(dio);
  });

  test('searchMovies sends bearer auth and search query params', () async {
    adapter.responseJson = {
      'page': 2,
      'total_pages': 5,
      'results': [
        {'id': 11, 'title': 'Avatar'},
      ],
    };

    final result = await repository.searchMovies(query: 'avatar', page: 2);

    expect(result.isRight(), isTrue);
    final page = result.getOrElse(
      () => const SearchMoviesPage(movies: [], page: 0, totalPages: 0),
    );
    expect(page.movies.single.title, 'Avatar');
    expect(page.page, 2);
    expect(page.totalPages, 5);
    expect(adapter.lastOptions?.path, '/search/movie');
    expect(adapter.lastOptions?.queryParameters['query'], 'avatar');
    expect(adapter.lastOptions?.queryParameters['page'], 2);
    expect(adapter.lastOptions?.queryParameters['language'], 'en-US');
    expect(adapter.lastOptions?.queryParameters['include_adult'], false);
    expect(adapter.lastOptions?.headers['Authorization'], 'Bearer test-token');
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
