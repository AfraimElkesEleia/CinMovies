import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cinmovies_app/features/home/data/home_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeAdapter adapter;
  late HomeRepository repository;

  setUp(() {
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
    expect(adapter.lastOptions?.headers['Authorization'], isNull);
  });

  test('fetchMovieSection uses upcoming endpoint for New Releases', () async {
    adapter.responseJson = {'page': 1, 'total_pages': 3, 'results': const []};

    await repository.fetchMovieSection(
      section: HomeMovieSection.upcoming,
      page: 1,
    );

    expect(adapter.lastOptions?.path, '/movie/upcoming');
    expect(adapter.lastOptions?.queryParameters['language'], 'en-US');
  });

  test('fetchForYouMovies uses OR genre filtering and safe defaults', () async {
    adapter.responseJson = {
      'page': 2,
      'total_pages': 5,
      'results': [
        {
          'id': 20,
          'title': 'Personalized Movie',
          'genre_ids': [878, 28],
        },
      ],
    };

    final result = await repository.fetchForYouMovies(
      genreIds: const [878, 28, 28],
      page: 2,
    );

    expect(result.isRight(), isTrue);
    expect(adapter.lastOptions?.path, '/discover/movie');
    expect(adapter.lastOptions?.queryParameters, containsPair('page', 2));
    expect(
      adapter.lastOptions?.queryParameters,
      containsPair('with_genres', '28|878'),
    );
    expect(
      adapter.lastOptions?.queryParameters,
      containsPair('sort_by', 'popularity.desc'),
    );
    expect(
      adapter.lastOptions?.queryParameters,
      containsPair('include_adult', false),
    );
    expect(
      adapter.lastOptions?.queryParameters,
      containsPair('include_video', false),
    );

    final page = result.getOrElse(
      () => const MovieSectionPage(movies: [], page: 0, totalPages: 0),
    );
    expect(page.movies.single.genres, ['Sci-Fi', 'Action']);
    expect(page.page, 2);
    expect(page.totalPages, 5);
  });

  test('For You movie section retains genre filters', () async {
    adapter.responseJson = {'page': 1, 'total_pages': 1, 'results': const []};

    await repository.fetchMovieSection(
      section: HomeMovieSection.forYou,
      page: 1,
      genreIds: const [35, 18],
    );

    expect(adapter.lastOptions?.path, '/discover/movie');
    expect(
      adapter.lastOptions?.queryParameters['with_genres'],
      '18|35',
    );
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
