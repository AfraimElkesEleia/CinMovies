import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cinmovies_app/features/home/data/home_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeAdapter adapter;
  late HomeRepository repository;

  setUp(() {
    dotenv.loadFromString(envString: 'TMDB_API_KEY=test-token');
    adapter = _FakeAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.themoviedb.org/3'))
      ..httpClientAdapter = adapter;
    repository = HomeRepository(dio);
  });

  test('fetchMovieSection uses popular endpoint for Trending Now', () async {
    adapter.responseJson = {
      'page': 2,
      'total_pages': 4,
      'results': [
        {'id': 10, 'title': 'Popular Movie'},
      ],
    };

    final result = await repository.fetchMovieSection(
      section: HomeMovieSection.popular,
      page: 2,
    );

    expect(result.isRight(), isTrue);
    final page = result.getOrElse(
      () => const MovieSectionPage(movies: [], page: 0, totalPages: 0),
    );
    expect(page.movies.single.title, 'Popular Movie');
    expect(page.page, 2);
    expect(page.totalPages, 4);
    expect(adapter.lastOptions?.path, '/movie/popular');
    expect(adapter.lastOptions?.queryParameters['page'], 2);
    expect(adapter.lastOptions?.headers['Authorization'], 'Bearer test-token');
  });

  test('fetchMovieSection uses upcoming endpoint for New Releases', () async {
    adapter.responseJson = {
      'page': 1,
      'total_pages': 3,
      'results': const [],
    };

    await repository.fetchMovieSection(
      section: HomeMovieSection.upcoming,
      page: 1,
    );

    expect(adapter.lastOptions?.path, '/movie/upcoming');
    expect(adapter.lastOptions?.queryParameters['language'], 'en-US');
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
