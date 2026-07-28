import 'dart:convert';

import 'package:cinmovies_app/core/config/env_config.dart';
import 'package:cinmovies_app/core/error/exceptions.dart';
import 'package:cinmovies_app/features/ai/domain/entities/movie_chat_models.dart';
import 'package:cinmovies_app/features/home/data/tmdb_movie_mapper.dart';
import 'package:dio/dio.dart';

class MovieChatAiDataSource {
  MovieChatAiDataSource(
    this._tmdb,
    this._gemini, {
    String? model,
  }) : _model = model ?? EnvConfig.geminiModel;

  static const maximumContextMessages = 10;

  final Dio _tmdb;
  final Dio _gemini;
  final String _model;

  Future<MovieChatDraft> generate({
    required String message,
    required String locale,
    required List<MovieChatMessage> context,
  }) async {
    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty || normalizedMessage.length > 1000) {
      throw const ServerException(
        message: 'Enter a movie question under 1,000 characters.',
      );
    }

    final recentContext = context.length <= maximumContextMessages
        ? context
        : context.sublist(context.length - maximumContextMessages);
    final plan = await _createPlan(
      message: normalizedMessage,
      locale: locale,
      context: recentContext,
    );
    final catalog = plan.intent.usesCatalog
        ? await _loadCatalog(plan, locale, recentContext)
        : const <_CanonicalMovie>[];
    return _createAnswer(
      message: normalizedMessage,
      locale: locale,
      context: recentContext,
      plan: plan,
      catalog: catalog,
    );
  }

  Future<_MoviePlan> _createPlan({
    required String message,
    required String locale,
    required List<MovieChatMessage> context,
  }) async {
    final output = await _generateJson(
      systemInstruction: _plannerInstruction,
      prompt: jsonEncode({
        'locale': locale,
        'currentYear': DateTime.now().toUtc().year,
        'recentConversation': _contextJson(context),
        'userMessage': message,
      }),
      schema: _planSchema,
    );
    return _MoviePlan.fromJson(output);
  }

  Future<List<_CanonicalMovie>> _loadCatalog(
    _MoviePlan plan,
    String locale,
    List<MovieChatMessage> context,
  ) async {
    final language = _tmdbLocale(locale);
    final genresResponse = await _tmdb.get<Map<String, dynamic>>(
      '/genre/movie/list',
      queryParameters: {'language': language},
    );
    final genreNames = <int, String>{};
    final genreIds = <String, int>{};
    final genreRows = _list(genresResponse.data?['genres']);
    for (final row in genreRows) {
      final id = _integer(row['id']);
      final name = _shortString(row['name'], 60);
      if (id == null || name == null) continue;
      genreNames[id] = name;
      genreIds[name.toLowerCase()] = id;
    }

    final candidates = <Map<String, dynamic>>[];
    final operation = plan.operation;

    final similarTo = operation.similarTo;
    if (similarTo != null) {
      final seedResponse = await _tmdb.get<Map<String, dynamic>>(
        '/search/movie',
        queryParameters: {
          'query': similarTo,
          'language': language,
          'include_adult': false,
          'page': 1,
        },
      );
      final seed = _results(seedResponse.data).firstOrNull;
      final seedId = _integer(seed?['id']);
      if (seedId != null) {
        final similarResponse = await _tmdb.get<Map<String, dynamic>>(
          '/movie/$seedId/similar',
          queryParameters: {'language': language, 'page': 1},
        );
        candidates.addAll(_results(similarResponse.data).take(8));
      }
    }

    for (final title in operation.titles) {
      final response = await _tmdb.get<Map<String, dynamic>>(
        '/search/movie',
        queryParameters: {
          'query': title,
          'language': language,
          'include_adult': false,
          'page': 1,
        },
      );
      candidates.addAll(_results(response.data).take(2));
    }

    final shouldDiscover =
        operation.titles.isEmpty &&
        operation.similarTo == null &&
        (plan.intent == _MovieIntent.recommendation ||
            plan.intent == _MovieIntent.similar);
    if (shouldDiscover) {
      final includedGenres = operation.genres
          .map((name) => genreIds[name.toLowerCase()])
          .whereType<int>()
          .toList();
      final excludedGenres = operation.excludedGenres
          .map((name) => genreIds[name.toLowerCase()])
          .whereType<int>()
          .toList();
      final response = await _tmdb.get<Map<String, dynamic>>(
        '/discover/movie',
        queryParameters: {
          'language': language,
          'include_adult': false,
          'page': 1,
          'sort_by': operation.minRating == null
              ? 'popularity.desc'
              : 'vote_average.desc',
          if (includedGenres.isNotEmpty)
            'with_genres': includedGenres.join(','),
          if (excludedGenres.isNotEmpty)
            'without_genres': excludedGenres.join(','),
          if (operation.originalLanguage != null)
            'with_original_language': operation.originalLanguage,
          if (operation.fromYear != null)
            'primary_release_date.gte': '${operation.fromYear}-01-01',
          if (operation.toYear != null)
            'primary_release_date.lte': '${operation.toYear}-12-31',
          if (operation.minRating != null)
            'vote_average.gte': operation.minRating,
          if (operation.minRating != null) 'vote_count.gte': 100,
          if (operation.maxRuntimeMinutes != null)
            'with_runtime.lte': operation.maxRuntimeMinutes,
        },
      );
      candidates.addAll(_results(response.data).take(8));
    }

    final ids = <int>[];
    if (operation.useContextMovies) {
      for (final message in context) {
        for (final recommendation in message.recommendations) {
          final id = int.tryParse(recommendation.movie.id);
          if (id != null && id > 0 && !ids.contains(id)) ids.add(id);
        }
      }
    }
    for (final row in candidates) {
      final id = _integer(row['id']);
      if (id != null && id > 0 && !ids.contains(id)) ids.add(id);
    }

    final details = await Future.wait(
      ids.take(8).map((id) async {
        try {
          final response = await _tmdb.get<Map<String, dynamic>>(
            '/movie/$id',
            queryParameters: {
              'language': language,
              'append_to_response': 'release_dates',
            },
          );
          return _CanonicalMovie.fromJson(response.data, genreNames);
        } on DioException {
          return null;
        } on FormatException {
          return null;
        }
      }),
    );
    final resolved = details.whereType<_CanonicalMovie>().toList();
    if (ids.isNotEmpty && resolved.isEmpty) {
      throw const ServerException(
        message: 'Movie information is temporarily unavailable. Try again.',
      );
    }
    if (plan.intent != _MovieIntent.recommendation &&
        plan.intent != _MovieIntent.similar) {
      return resolved;
    }
    return resolved.where((movie) => _matches(movie, operation)).toList();
  }

  bool _matches(_CanonicalMovie movie, _CatalogOperation operation) {
    final exclusions = operation.excludedGenres
        .map((genre) => genre.toLowerCase())
        .toSet();
    if (movie.genres.any(
      (genre) => exclusions.contains(genre.toLowerCase()),
    )) {
      return false;
    }
    final maximumRuntime = operation.maxRuntimeMinutes;
    if (maximumRuntime != null &&
        (movie.runtime == null || movie.runtime! > maximumRuntime)) {
      return false;
    }
    final minimumRating = operation.minRating;
    if (minimumRating != null && movie.voteAverage < minimumRating) {
      return false;
    }
    final year = movie.releaseDate == null
        ? null
        : int.tryParse(movie.releaseDate!.substring(0, 4));
    if (operation.fromYear != null &&
        (year == null || year < operation.fromYear!)) {
      return false;
    }
    if (operation.toYear != null &&
        (year == null || year > operation.toYear!)) {
      return false;
    }
    if (operation.originalLanguage != null &&
        movie.originalLanguage != operation.originalLanguage) {
      return false;
    }
    return true;
  }

  Future<MovieChatDraft> _createAnswer({
    required String message,
    required String locale,
    required List<MovieChatMessage> context,
    required _MoviePlan plan,
    required List<_CanonicalMovie> catalog,
  }) async {
    final output = await _generateJson(
      systemInstruction: _answerInstruction,
      prompt: jsonEncode({
        'locale': locale,
        'intent': plan.intent.value,
        'catalogOperation': plan.operation.toJson(),
        'recentConversation': _contextJson(context),
        'userMessage': message,
        'canonicalCatalog': catalog.map((movie) => movie.promptJson).toList(),
      }),
      schema: _answerSchema,
    );

    final content = _shortString(output['content'], 1800);
    if (content == null) {
      throw const ServerException(
        message: 'The movie assistant returned an invalid answer. Try again.',
      );
    }

    final byId = {for (final movie in catalog) movie.id: movie};
    final recommendations = <MovieRecommendation>[];
    for (final item in _list(output['selectedMovies']).take(5)) {
      final id = _integer(item['tmdbId']);
      final reason = _shortString(item['reason'], 280);
      final canonical = id == null ? null : byId[id];
      if (canonical == null ||
          reason == null ||
          recommendations.any(
            (item) => item.movie.id == canonical.id.toString(),
          )) {
        continue;
      }
      recommendations.add(
        MovieRecommendation(
          movie: TmdbMovieMapper.fromJson(canonical.movieJson),
          reason: reason,
        ),
      );
    }

    return MovieChatDraft(
      content: content,
      recommendations: recommendations,
      suggestedReplies: _strings(
        output['suggestedReplies'],
        maximumItems: 4,
        maximumLength: 80,
      ),
    );
  }

  Future<Map<String, dynamic>> _generateJson({
    required String systemInstruction,
    required String prompt,
    required Map<String, dynamic> schema,
  }) async {
    try {
      final model = Uri.encodeComponent(_model);
      final response = await _gemini.post<Map<String, dynamic>>(
        '/models/$model:generateContent',
        data: {
          'systemInstruction': {
            'parts': [
              {'text': systemInstruction},
            ],
          },
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
            'responseJsonSchema': schema,
            'maxOutputTokens': 2048,
            'temperature': 0.25,
          },
        },
      );
      final text = _geminiText(response.data);
      final decoded = jsonDecode(text);
      final result = _map(decoded);
      if (result == null) throw const FormatException();
      return result;
    } on DioException catch (error) {
      if (_isNetworkFailure(error)) rethrow;
      throw ServerException(
        message: error.response?.statusCode == 429
            ? 'The movie assistant is busy. Try again shortly.'
            : 'The movie assistant is temporarily unavailable. Try again.',
      );
    } on Object {
      throw const ServerException(
        message: 'The movie assistant returned an invalid response. Try again.',
      );
    }
  }

  bool _isNetworkFailure(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => true,
      _ => false,
    };
  }

  String _geminiText(Object? value) {
    final response = _map(value);
    final candidates = response?['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const FormatException();
    }
    final candidate = _map(candidates.first);
    final content = _map(candidate?['content']);
    final parts = content?['parts'];
    if (parts is! List || parts.isEmpty) throw const FormatException();
    final part = _map(parts.first);
    final text = part?['text'];
    if (text is! String || text.trim().isEmpty) throw const FormatException();
    return text.trim();
  }

  List<Map<String, dynamic>> _contextJson(List<MovieChatMessage> context) {
    return context.map((message) {
      return {
        'role': message.role.value,
        'content': message.content,
        'movieIds': message.recommendations
            .map((item) => int.tryParse(item.movie.id))
            .whereType<int>()
            .take(5)
            .toList(),
      };
    }).toList();
  }
}

class MovieChatDraft {
  const MovieChatDraft({
    required this.content,
    required this.recommendations,
    required this.suggestedReplies,
  });

  final String content;
  final List<MovieRecommendation> recommendations;
  final List<String> suggestedReplies;
}

enum _MovieIntent {
  recommendation,
  movieQuestion,
  comparison,
  similar,
  clarification,
  offTopic;

  String get value => switch (this) {
    recommendation => 'recommendation',
    movieQuestion => 'movie_question',
    comparison => 'comparison',
    similar => 'similar',
    clarification => 'clarification',
    offTopic => 'off_topic',
  };

  bool get usesCatalog => this != clarification && this != offTopic;

  static _MovieIntent? tryParse(Object? value) {
    for (final intent in values) {
      if (intent.value == value) return intent;
    }
    return null;
  }
}

class _MoviePlan {
  const _MoviePlan({required this.intent, required this.operation});

  factory _MoviePlan.fromJson(Object? value) {
    final map = _map(value);
    final intent = _MovieIntent.tryParse(map?['intent']);
    final operation = _map(map?['operation']);
    if (intent == null || operation == null) {
      throw const ServerException(
        message: 'The movie assistant could not understand that request.',
      );
    }
    return _MoviePlan(
      intent: intent,
      operation: _CatalogOperation.fromJson(operation),
    );
  }

  final _MovieIntent intent;
  final _CatalogOperation operation;
}

class _CatalogOperation {
  const _CatalogOperation({
    required this.titles,
    required this.genres,
    required this.excludedGenres,
    required this.preferenceNotes,
    required this.useContextMovies,
    this.similarTo,
    this.originalLanguage,
    this.fromYear,
    this.toYear,
    this.minRating,
    this.maxRuntimeMinutes,
  });

  factory _CatalogOperation.fromJson(Map<String, dynamic> value) {
    return _CatalogOperation(
      titles: _strings(value['titles'], maximumItems: 3, maximumLength: 120),
      similarTo: _shortString(value['similarTo'], 120),
      genres: _strings(value['genres'], maximumItems: 4, maximumLength: 40),
      excludedGenres: _strings(
        value['excludedGenres'],
        maximumItems: 4,
        maximumLength: 40,
      ),
      originalLanguage: _shortString(value['originalLanguage'], 8),
      fromYear: _boundedInteger(value['fromYear'], 1888, 2100),
      toYear: _boundedInteger(value['toYear'], 1888, 2100),
      minRating: _boundedDouble(value['minRating'], 0, 10),
      maxRuntimeMinutes: _boundedInteger(
        value['maxRuntimeMinutes'],
        20,
        600,
      ),
      preferenceNotes: _shortString(value['preferenceNotes'], 240) ?? '',
      useContextMovies: value['useContextMovies'] == true,
    );
  }

  final List<String> titles;
  final String? similarTo;
  final List<String> genres;
  final List<String> excludedGenres;
  final String? originalLanguage;
  final int? fromYear;
  final int? toYear;
  final double? minRating;
  final int? maxRuntimeMinutes;
  final String preferenceNotes;
  final bool useContextMovies;

  Map<String, dynamic> toJson() {
    return {
      'titles': titles,
      if (similarTo != null) 'similarTo': similarTo,
      'genres': genres,
      'excludedGenres': excludedGenres,
      if (originalLanguage != null) 'originalLanguage': originalLanguage,
      if (fromYear != null) 'fromYear': fromYear,
      if (toYear != null) 'toYear': toYear,
      if (minRating != null) 'minRating': minRating,
      if (maxRuntimeMinutes != null)
        'maxRuntimeMinutes': maxRuntimeMinutes,
      'preferenceNotes': preferenceNotes,
      'useContextMovies': useContextMovies,
    };
  }
}

class _CanonicalMovie {
  const _CanonicalMovie({
    required this.id,
    required this.title,
    required this.overview,
    required this.voteAverage,
    required this.voteCount,
    required this.popularity,
    required this.genres,
    this.originalTitle,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.runtime,
    this.ageRating,
    this.originalLanguage,
  });

  factory _CanonicalMovie.fromJson(
    Object? value,
    Map<int, String> genreNames,
  ) {
    final map = _map(value);
    final id = _integer(map?['id']);
    final title =
        _shortString(map?['title'], 240) ??
        _shortString(map?['original_title'], 240);
    if (map == null || id == null || id <= 0 || title == null) {
      throw const FormatException();
    }
    final genres = <String>[];
    for (final item in _list(map['genres'])) {
      final name = _shortString(item['name'], 60);
      final genreId = _integer(item['id']);
      final resolvedName = name ?? (genreId == null ? null : genreNames[genreId]);
      if (resolvedName != null && !genres.contains(resolvedName)) {
        genres.add(resolvedName);
      }
    }
    return _CanonicalMovie(
      id: id,
      title: title,
      originalTitle: _shortString(map['original_title'], 240),
      overview: _shortString(map['overview'], 3000) ?? '',
      posterPath: _shortString(map['poster_path'], 300),
      backdropPath: _shortString(map['backdrop_path'], 300),
      releaseDate: _date(map['release_date']),
      runtime: _integer(map['runtime']),
      ageRating: _certification(map['release_dates']),
      voteAverage: _number(map['vote_average']) ?? 0,
      voteCount: _integer(map['vote_count']) ?? 0,
      popularity: _number(map['popularity']) ?? 0,
      originalLanguage: _shortString(map['original_language'], 8),
      genres: genres,
    );
  }

  final int id;
  final String title;
  final String? originalTitle;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final int? runtime;
  final String? ageRating;
  final double voteAverage;
  final int voteCount;
  final double popularity;
  final String? originalLanguage;
  final List<String> genres;

  Map<String, dynamic> get movieJson => {
    'id': id,
    'title': title,
    'original_title': originalTitle,
    'overview': overview,
    'poster_path': posterPath,
    'backdrop_path': backdropPath,
    'release_date': releaseDate,
    'runtime': runtime,
    'age_rating': ageRating,
    'vote_average': voteAverage,
    'vote_count': voteCount,
    'popularity': popularity,
    'original_language': originalLanguage,
    'genres': genres,
  };

  Map<String, dynamic> get promptJson => {
    'tmdbId': id,
    'title': title,
    'originalTitle': originalTitle,
    'overview': overview,
    'releaseDate': releaseDate,
    'runtimeMinutes': runtime,
    'ageRating': ageRating,
    'rating': voteAverage,
    'voteCount': voteCount,
    'originalLanguage': originalLanguage,
    'genres': genres,
  };
}

const _plannerInstruction = '''
You are the single intent and catalog planner for the CinMovies movie assistant.
Convert the request into one small TMDB catalog operation. Never invent a TMDB
ID. Put at most three named movies in titles. Use similarTo only when the user
asks for movies like a named movie. Set useContextMovies only when the user
refers to movies in the recent conversation. Put mood and tone in
preferenceNotes. Capture genres, exclusions, ISO 639-1 original language,
release years, minimum rating, and maximum runtime only when requested. Use
clarification only when an essential preference is missing. Use off_topic for
requests unrelated to movies or closely related cinema questions. For
clarification and off_topic, return an empty operation. Return only JSON.
''';

const _answerInstruction = '''
You are CinMovies AI, a concise movie assistant. Use only the canonical TMDB
catalog records supplied in the current prompt for titles, dates, runtimes,
genres, ratings, and other movie facts. Never invent streaming availability or
catalog facts, and never claim to have watched a movie. Prefer a few strong
matches with brief reasons. Respect exclusions. Avoid spoilers unless explicitly
requested; if requested, start with a spoiler warning. Keep comparisons balanced
and spoiler-free by default. Match the user's language when practical. For a
clarification intent ask exactly one concise question. For off_topic, briefly
redirect to movies. Select only tmdbId values present in canonicalCatalog.
Return only JSON.
''';

const _planSchema = <String, dynamic>{
  'type': 'object',
  'additionalProperties': false,
  'properties': {
    'intent': {
      'type': 'string',
      'enum': [
        'recommendation',
        'movie_question',
        'comparison',
        'similar',
        'clarification',
        'off_topic',
      ],
    },
    'operation': {
      'type': 'object',
      'additionalProperties': false,
      'properties': {
        'titles': {
          'type': 'array',
          'maxItems': 3,
          'items': {'type': 'string'},
        },
        'similarTo': {'type': 'string'},
        'genres': {
          'type': 'array',
          'maxItems': 4,
          'items': {'type': 'string'},
        },
        'excludedGenres': {
          'type': 'array',
          'maxItems': 4,
          'items': {'type': 'string'},
        },
        'originalLanguage': {'type': 'string'},
        'fromYear': {
          'type': 'integer',
          'minimum': 1888,
          'maximum': 2100,
        },
        'toYear': {
          'type': 'integer',
          'minimum': 1888,
          'maximum': 2100,
        },
        'minRating': {'type': 'number', 'minimum': 0, 'maximum': 10},
        'maxRuntimeMinutes': {
          'type': 'integer',
          'minimum': 20,
          'maximum': 600,
        },
        'preferenceNotes': {'type': 'string'},
        'useContextMovies': {'type': 'boolean'},
      },
      'required': [
        'titles',
        'genres',
        'excludedGenres',
        'preferenceNotes',
        'useContextMovies',
      ],
    },
  },
  'required': ['intent', 'operation'],
};

const _answerSchema = <String, dynamic>{
  'type': 'object',
  'additionalProperties': false,
  'properties': {
    'content': {'type': 'string'},
    'selectedMovies': {
      'type': 'array',
      'maxItems': 5,
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'properties': {
          'tmdbId': {'type': 'integer', 'minimum': 1},
          'reason': {'type': 'string'},
        },
        'required': ['tmdbId', 'reason'],
      },
    },
    'suggestedReplies': {
      'type': 'array',
      'maxItems': 4,
      'items': {'type': 'string'},
    },
  },
  'required': ['content', 'selectedMovies', 'suggestedReplies'],
};

List<Map<String, dynamic>> _results(Object? value) {
  final map = _map(value);
  return _list(map?['results']);
}

List<Map<String, dynamic>> _list(Object? value) {
  if (value is! Iterable) return const [];
  return value.map(_map).whereType<Map<String, dynamic>>().toList();
}

Map<String, dynamic>? _map(Object? value) {
  if (value is! Map) return null;
  try {
    return Map<String, dynamic>.from(value);
  } on Object {
    return null;
  }
}

List<String> _strings(
  Object? value, {
  required int maximumItems,
  required int maximumLength,
}) {
  if (value is! Iterable) return const [];
  final result = <String>[];
  for (final item in value) {
    final text = _shortString(item, maximumLength);
    if (text != null && !result.contains(text)) result.add(text);
    if (result.length == maximumItems) break;
  }
  return result;
}

String? _shortString(Object? value, int maximumLength) {
  if (value is! String) return null;
  final text = value.trim();
  if (text.isEmpty) return null;
  return text.length <= maximumLength
      ? text
      : text.substring(0, maximumLength);
}

int? _integer(Object? value) {
  final number = value is num ? value : num.tryParse(value?.toString() ?? '');
  if (number == null || !number.isFinite || number != number.round()) {
    return null;
  }
  return number.toInt();
}

double? _number(Object? value) {
  final number = value is num ? value : num.tryParse(value?.toString() ?? '');
  return number == null || !number.isFinite ? null : number.toDouble();
}

int? _boundedInteger(Object? value, int minimum, int maximum) {
  final number = _integer(value);
  return number != null && number >= minimum && number <= maximum
      ? number
      : null;
}

double? _boundedDouble(Object? value, double minimum, double maximum) {
  final number = _number(value);
  return number != null && number >= minimum && number <= maximum
      ? number
      : null;
}

String? _date(Object? value) {
  final text = _shortString(value, 10);
  return text != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)
      ? text
      : null;
}

String? _certification(Object? value) {
  final map = _map(value);
  final countries = _list(map?['results']);
  if (countries.isEmpty) return null;
  final preferred = countries.firstWhere(
    (country) => country['iso_3166_1'] == 'US',
    orElse: () => countries.first,
  );
  for (final row in _list(preferred['release_dates'])) {
    final value = _shortString(row['certification'], 20);
    if (value != null) return value;
  }
  return null;
}

String _tmdbLocale(String locale) {
  final normalized = locale.replaceAll('_', '-');
  if (RegExp(r'^[a-z]{2,3}-[A-Z]{2}$').hasMatch(normalized)) {
    return normalized;
  }
  final language = normalized.split('-').first.toLowerCase();
  return RegExp(r'^[a-z]{2,3}$').hasMatch(language)
      ? '$language-US'
      : 'en-US';
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
