import 'dart:convert';

import 'package:cinmovies_app/core/config/env_config.dart';
import 'package:cinmovies_app/core/error/exceptions.dart';
import 'package:cinmovies_app/features/ai/domain/entities/movie_chat_models.dart';
import 'package:dio/dio.dart';

class GeminiService {
  GeminiService(
    this._dio, {
    String? model,
  }) : _model = model ?? EnvConfig.geminiModel;

  final Dio _dio;
  final String _model;

  Future<MoviePlan> createPlan({
    required String message,
    required String locale,
    required List<MovieChatMessage> context,
  }) async {
    final output = await _generateJson(
      systemInstruction: _plannerInstruction,
      prompt: jsonEncode({
        'locale': locale,
        'currentYear': DateTime.now().toUtc().year,
        'recentConversation': contextJson(context),
        'userMessage': message,
      }),
      schema: _planSchema,
    );
    return MoviePlan.fromJson(output);
  }

  Future<Map<String, dynamic>> createAnswer({
    required String message,
    required String locale,
    required List<MovieChatMessage> context,
    required MoviePlan plan,
    required List<Map<String, dynamic>> catalogPromptJson,
  }) async {
    return _generateJson(
      systemInstruction: _answerInstruction,
      prompt: jsonEncode({
        'locale': locale,
        'intent': plan.intent.value,
        'catalogOperation': plan.operation.toJson(),
        'recentConversation': contextJson(context),
        'userMessage': message,
        'canonicalCatalog': catalogPromptJson,
      }),
      schema: _answerSchema,
    );
  }

  Future<Map<String, dynamic>> _generateJson({
    required String systemInstruction,
    required String prompt,
    required Map<String, dynamic> schema,
  }) async {
    try {
      final model = Uri.encodeComponent(_model);
      final response = await _dio.post<Map<String, dynamic>>(
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
      final result = jsonMap(decoded);
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
    final response = jsonMap(value);
    final candidates = response?['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const FormatException();
    }
    final candidate = jsonMap(candidates.first);
    final content = jsonMap(candidate?['content']);
    final parts = content?['parts'];
    if (parts is! List || parts.isEmpty) throw const FormatException();
    final part = jsonMap(parts.first);
    final text = part?['text'];
    if (text is! String || text.trim().isEmpty) throw const FormatException();
    return text.trim();
  }

  static List<Map<String, dynamic>> contextJson(
    List<MovieChatMessage> context,
  ) {
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

// ---------------------------------------------------------------------------
// Intent & plan models
// ---------------------------------------------------------------------------

enum MovieIntent {
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

  static MovieIntent? tryParse(Object? value) {
    for (final intent in values) {
      if (intent.value == value) return intent;
    }
    return null;
  }
}

class MoviePlan {
  const MoviePlan({required this.intent, required this.operation});

  factory MoviePlan.fromJson(Object? value) {
    final map = jsonMap(value);
    final intent = MovieIntent.tryParse(map?['intent']);
    final operation = jsonMap(map?['operation']);
    if (intent == null || operation == null) {
      throw const ServerException(
        message: 'The movie assistant could not understand that request.',
      );
    }
    return MoviePlan(
      intent: intent,
      operation: CatalogOperation.fromJson(operation),
    );
  }

  final MovieIntent intent;
  final CatalogOperation operation;
}

class CatalogOperation {
  const CatalogOperation({
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

  factory CatalogOperation.fromJson(Map<String, dynamic> value) {
    return CatalogOperation(
      titles: jsonStrings(value['titles'], maximumItems: 3, maximumLength: 120),
      similarTo: shortString(value['similarTo'], 120),
      genres: jsonStrings(value['genres'], maximumItems: 4, maximumLength: 40),
      excludedGenres: jsonStrings(
        value['excludedGenres'],
        maximumItems: 4,
        maximumLength: 40,
      ),
      originalLanguage: shortString(value['originalLanguage'], 8),
      fromYear: boundedInteger(value['fromYear'], 1888, 2100),
      toYear: boundedInteger(value['toYear'], 1888, 2100),
      minRating: boundedDouble(value['minRating'], 0, 10),
      maxRuntimeMinutes: boundedInteger(
        value['maxRuntimeMinutes'],
        20,
        600,
      ),
      preferenceNotes: shortString(value['preferenceNotes'], 240) ?? '',
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

// ---------------------------------------------------------------------------
// Prompt constants
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// JSON schemas
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Shared JSON parsing helpers
// ---------------------------------------------------------------------------

Map<String, dynamic>? jsonMap(Object? value) {
  if (value is! Map) return null;
  try {
    return Map<String, dynamic>.from(value);
  } on Object {
    return null;
  }
}

List<Map<String, dynamic>> jsonMapList(Object? value) {
  if (value is! Iterable) return const [];
  return value.map(jsonMap).whereType<Map<String, dynamic>>().toList();
}

List<String> jsonStrings(
  Object? value, {
  required int maximumItems,
  required int maximumLength,
}) {
  if (value is! Iterable) return const [];
  final result = <String>[];
  for (final item in value) {
    final text = shortString(item, maximumLength);
    if (text != null && !result.contains(text)) result.add(text);
    if (result.length == maximumItems) break;
  }
  return result;
}

String? shortString(Object? value, int maximumLength) {
  if (value is! String) return null;
  final text = value.trim();
  if (text.isEmpty) return null;
  return text.length <= maximumLength
      ? text
      : text.substring(0, maximumLength);
}

int? jsonInteger(Object? value) {
  final number = value is num ? value : num.tryParse(value?.toString() ?? '');
  if (number == null || !number.isFinite || number != number.round()) {
    return null;
  }
  return number.toInt();
}

double? jsonNumber(Object? value) {
  final number = value is num ? value : num.tryParse(value?.toString() ?? '');
  return number == null || !number.isFinite ? null : number.toDouble();
}

int? boundedInteger(Object? value, int minimum, int maximum) {
  final number = jsonInteger(value);
  return number != null && number >= minimum && number <= maximum
      ? number
      : null;
}

double? boundedDouble(Object? value, double minimum, double maximum) {
  final number = jsonNumber(value);
  return number != null && number >= minimum && number <= maximum
      ? number
      : null;
}
