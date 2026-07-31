import 'package:cinmovies_app/core/error/exceptions.dart';
import 'package:cinmovies_app/features/ai/data/gemini_service.dart';
import 'package:cinmovies_app/features/ai/domain/entities/movie_chat_models.dart';
import 'package:dio/dio.dart';

class TmdbCatalogService {
  const TmdbCatalogService(this._dio);

  final Dio _dio;

  Future<List<CanonicalMovie>> loadCatalog({
    required MoviePlan plan,
    required String locale,
    required List<MovieChatMessage> context,
  }) async {
    final language = _tmdbLocale(locale);
    final genresResponse = await _dio.get<Map<String, dynamic>>(
      '/genre/movie/list',
      queryParameters: {'language': language},
    );
    final genreNames = <int, String>{};
    final genreIds = <String, int>{};
    final genreRows = jsonMapList(genresResponse.data?['genres']);
    for (final row in genreRows) {
      final id = jsonInteger(row['id']);
      final name = shortString(row['name'], 60);
      if (id == null || name == null) continue;
      genreNames[id] = name;
      genreIds[name.toLowerCase()] = id;
    }

    final candidates = <Map<String, dynamic>>[];
    final operation = plan.operation;

    final similarTo = operation.similarTo;
    if (similarTo != null) {
      final seedResponse = await _dio.get<Map<String, dynamic>>(
        '/search/movie',
        queryParameters: {
          'query': similarTo,
          'language': language,
          'include_adult': false,
          'page': 1,
        },
      );
      final seed = _results(seedResponse.data).firstOrNull;
      final seedId = jsonInteger(seed?['id']);
      if (seedId != null) {
        final similarResponse = await _dio.get<Map<String, dynamic>>(
          '/movie/$seedId/similar',
          queryParameters: {'language': language, 'page': 1},
        );
        candidates.addAll(_results(similarResponse.data).take(8));
      }
    }

    for (final title in operation.titles) {
      final response = await _dio.get<Map<String, dynamic>>(
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
        (plan.intent == MovieIntent.recommendation ||
            plan.intent == MovieIntent.similar);
    if (shouldDiscover) {
      final includedGenres = operation.genres
          .map((name) => genreIds[name.toLowerCase()])
          .whereType<int>()
          .toList();
      final excludedGenres = operation.excludedGenres
          .map((name) => genreIds[name.toLowerCase()])
          .whereType<int>()
          .toList();
      final response = await _dio.get<Map<String, dynamic>>(
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
      final id = jsonInteger(row['id']);
      if (id != null && id > 0 && !ids.contains(id)) ids.add(id);
    }

    final details = await Future.wait(
      ids.take(8).map((id) async {
        try {
          final response = await _dio.get<Map<String, dynamic>>(
            '/movie/$id',
            queryParameters: {
              'language': language,
              'append_to_response': 'release_dates',
            },
          );
          return CanonicalMovie.fromJson(response.data, genreNames);
        } on DioException {
          return null;
        } on FormatException {
          return null;
        }
      }),
    );
    final resolved = details.whereType<CanonicalMovie>().toList();
    if (ids.isNotEmpty && resolved.isEmpty) {
      throw const ServerException(
        message: 'Movie information is temporarily unavailable. Try again.',
      );
    }
    if (plan.intent != MovieIntent.recommendation &&
        plan.intent != MovieIntent.similar) {
      return resolved;
    }
    return resolved.where((movie) => _matches(movie, operation)).toList();
  }

  bool _matches(CanonicalMovie movie, CatalogOperation operation) {
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

  List<Map<String, dynamic>> _results(Object? value) {
    final map = jsonMap(value);
    return jsonMapList(map?['results']);
  }
}

// ---------------------------------------------------------------------------
// Canonical movie model
// ---------------------------------------------------------------------------

class CanonicalMovie {
  const CanonicalMovie({
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

  factory CanonicalMovie.fromJson(
    Object? value,
    Map<int, String> genreNames,
  ) {
    final map = jsonMap(value);
    final id = jsonInteger(map?['id']);
    final title =
        shortString(map?['title'], 240) ??
        shortString(map?['original_title'], 240);
    if (map == null || id == null || id <= 0 || title == null) {
      throw const FormatException();
    }
    final genres = <String>[];
    for (final item in jsonMapList(map['genres'])) {
      final name = shortString(item['name'], 60);
      final genreId = jsonInteger(item['id']);
      final resolvedName =
          name ?? (genreId == null ? null : genreNames[genreId]);
      if (resolvedName != null && !genres.contains(resolvedName)) {
        genres.add(resolvedName);
      }
    }
    return CanonicalMovie(
      id: id,
      title: title,
      originalTitle: shortString(map['original_title'], 240),
      overview: shortString(map['overview'], 3000) ?? '',
      posterPath: shortString(map['poster_path'], 300),
      backdropPath: shortString(map['backdrop_path'], 300),
      releaseDate: _date(map['release_date']),
      runtime: jsonInteger(map['runtime']),
      ageRating: _certification(map['release_dates']),
      voteAverage: jsonNumber(map['vote_average']) ?? 0,
      voteCount: jsonInteger(map['vote_count']) ?? 0,
      popularity: jsonNumber(map['popularity']) ?? 0,
      originalLanguage: shortString(map['original_language'], 8),
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

// ---------------------------------------------------------------------------
// TMDB-specific parsing helpers
// ---------------------------------------------------------------------------

String? _date(Object? value) {
  final text = shortString(value, 10);
  return text != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)
      ? text
      : null;
}

String? _certification(Object? value) {
  final map = jsonMap(value);
  final countries = jsonMapList(map?['results']);
  if (countries.isEmpty) return null;
  final preferred = countries.firstWhere(
    (country) => country['iso_3166_1'] == 'US',
    orElse: () => countries.first,
  );
  for (final row in jsonMapList(preferred['release_dates'])) {
    final value = shortString(row['certification'], 20);
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
