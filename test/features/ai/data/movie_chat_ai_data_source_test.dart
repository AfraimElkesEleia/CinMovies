import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cinmovies_app/core/error/exceptions.dart';
import 'package:cinmovies_app/features/ai/data/movie_chat_ai_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _GeminiAdapter geminiAdapter;
  late _TmdbAdapter tmdbAdapter;
  late MovieChatAiDataSource dataSource;

  setUp(() {
    geminiAdapter = _GeminiAdapter();
    tmdbAdapter = _TmdbAdapter();
    final gemini = Dio(
      BaseOptions(baseUrl: 'https://generativelanguage.googleapis.com/v1beta'),
    )..httpClientAdapter = geminiAdapter;
    final tmdb = Dio(BaseOptions(baseUrl: 'https://api.themoviedb.org/3'))
      ..httpClientAdapter = tmdbAdapter;
    dataSource = MovieChatAiDataSource(tmdb, gemini, model: 'gemini-test');
  });

  test('grounds Gemini selections in canonical TMDB movie details', () async {
    final draft = await dataSource.generate(
      message: 'Recommend a thoughtful sci-fi movie',
      locale: 'en-US',
      context: const [],
    );

    expect(draft.content, 'Interstellar is a strong match.');
    expect(draft.suggestedReplies, ['Something lighter']);
    final recommendation = draft.recommendations.single;
    expect(recommendation.movie.id, '157336');
    expect(recommendation.movie.title, 'Interstellar');
    expect(recommendation.movie.duration, '2h 49m');
    expect(recommendation.reason, 'Thoughtful science fiction.');
    expect(tmdbAdapter.paths, contains('/movie/157336'));
    expect(geminiAdapter.requests, hasLength(2));
  });

  test('drops a model-selected ID that TMDB did not supply', () async {
    geminiAdapter.answer = {
      'content': 'I could not validate that title.',
      'selectedMovies': [
        {'tmdbId': 999999, 'reason': 'Invented ID'},
      ],
      'suggestedReplies': <String>[],
    };

    final draft = await dataSource.generate(
      message: 'Recommend a thoughtful sci-fi movie',
      locale: 'en',
      context: const [],
    );

    expect(draft.content, 'I could not validate that title.');
    expect(draft.recommendations, isEmpty);
  });

  test('rejects a malformed Gemini payload', () async {
    geminiAdapter.returnMalformedPayload = true;

    expect(
      () => dataSource.generate(
        message: 'Recommend a movie',
        locale: 'en',
        context: const [],
      ),
      throwsA(isA<ServerException>()),
    );
  });

  test('maps a Gemini rate limit to a retryable assistant error', () async {
    geminiAdapter.statusCode = 429;

    expect(
      () => dataSource.generate(
        message: 'Recommend a movie',
        locale: 'en',
        context: const [],
      ),
      throwsA(
        isA<ServerException>().having(
          (error) => error.message,
          'message',
          contains('busy'),
        ),
      ),
    );
  });

  test('reports TMDB detail failure instead of inventing movies', () async {
    tmdbAdapter.failDetails = true;

    expect(
      () => dataSource.generate(
        message: 'Recommend a thoughtful sci-fi movie',
        locale: 'en',
        context: const [],
      ),
      throwsA(
        isA<ServerException>().having(
          (error) => error.message,
          'message',
          contains('Movie information'),
        ),
      ),
    );
  });
}

class _GeminiAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  bool returnMalformedPayload = false;
  int statusCode = 200;
  Map<String, dynamic> answer = {
    'content': 'Interstellar is a strong match.',
    'selectedMovies': [
      {'tmdbId': 157336, 'reason': 'Thoughtful science fiction.'},
    ],
    'suggestedReplies': ['Something lighter'],
  };

  Map<String, dynamic> get plan => {
    'intent': 'recommendation',
    'operation': {
      'titles': ['Interstellar'],
      'genres': ['Science Fiction'],
      'excludedGenres': <String>[],
      'preferenceNotes': 'thoughtful',
      'useContextMovies': false,
    },
  };

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (statusCode != 200) {
      return _jsonResponse(
        {
          'error': {'message': 'provider failure'},
        },
        statusCode: statusCode,
      );
    }
    if (returnMalformedPayload) {
      return _jsonResponse({'candidates': const []});
    }
    final response = requests.length == 1 ? plan : answer;
    return _jsonResponse({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': jsonEncode(response)},
            ],
          },
        },
      ],
    });
  }
}

class _TmdbAdapter implements HttpClientAdapter {
  final List<String> paths = [];
  bool failDetails = false;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    if (failDetails && options.path == '/movie/157336') {
      return _jsonResponse(
        {
          'error': {'message': 'catalog failure'},
        },
        statusCode: 503,
      );
    }
    return switch (options.path) {
      '/genre/movie/list' => _jsonResponse({
        'genres': [
          {'id': 878, 'name': 'Science Fiction'},
        ],
      }),
      '/search/movie' => _jsonResponse({
        'results': [
          {'id': 157336, 'title': 'Interstellar'},
        ],
      }),
      '/movie/157336' => _jsonResponse({
        'id': 157336,
        'title': 'Interstellar',
        'original_title': 'Interstellar',
        'overview': 'Explorers travel through a wormhole.',
        'poster_path': '/poster.jpg',
        'backdrop_path': '/backdrop.jpg',
        'release_date': '2014-11-05',
        'runtime': 169,
        'vote_average': 8.7,
        'vote_count': 35000,
        'popularity': 120.5,
        'original_language': 'en',
        'genres': [
          {'id': 878, 'name': 'Science Fiction'},
        ],
        'release_dates': {
          'results': [
            {
              'iso_3166_1': 'US',
              'release_dates': [
                {'certification': 'PG-13'},
              ],
            },
          ],
        },
      }),
      _ => _jsonResponse({'results': const []}),
    };
  }
}

ResponseBody _jsonResponse(
  Map<String, dynamic> value, {
  int statusCode = 200,
}) {
  return ResponseBody.fromString(
    jsonEncode(value),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
