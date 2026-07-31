import 'package:cinmovies_app/core/error/exceptions.dart';
import 'package:cinmovies_app/features/ai/data/gemini_service.dart';
import 'package:cinmovies_app/features/ai/data/tmdb_catalog_service.dart';
import 'package:cinmovies_app/features/ai/domain/entities/movie_chat_models.dart';
import 'package:cinmovies_app/features/home/data/tmdb_movie_mapper.dart';

class MovieChatAiDataSource {
  const MovieChatAiDataSource(this._gemini, this._catalog);

  static const maximumContextMessages = 10;

  final GeminiService _gemini;
  final TmdbCatalogService _catalog;

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

    final plan = await _gemini.createPlan(
      message: normalizedMessage,
      locale: locale,
      context: recentContext,
    );

    final catalog = plan.intent.usesCatalog
        ? await _catalog.loadCatalog(
            plan: plan,
            locale: locale,
            context: recentContext,
          )
        : const <CanonicalMovie>[];

    return _buildDraft(
      message: normalizedMessage,
      locale: locale,
      context: recentContext,
      plan: plan,
      catalog: catalog,
    );
  }

  Future<MovieChatDraft> _buildDraft({
    required String message,
    required String locale,
    required List<MovieChatMessage> context,
    required MoviePlan plan,
    required List<CanonicalMovie> catalog,
  }) async {
    final output = await _gemini.createAnswer(
      message: message,
      locale: locale,
      context: context,
      plan: plan,
      catalogPromptJson: catalog.map((movie) => movie.promptJson).toList(),
    );

    final content = shortString(output['content'], 1800);
    if (content == null) {
      throw const ServerException(
        message: 'The movie assistant returned an invalid answer. Try again.',
      );
    }

    final byId = {for (final movie in catalog) movie.id: movie};
    final recommendations = <MovieRecommendation>[];
    for (final item in jsonMapList(output['selectedMovies']).take(5)) {
      final id = jsonInteger(item['tmdbId']);
      final reason = shortString(item['reason'], 280);
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
      suggestedReplies: jsonStrings(
        output['suggestedReplies'],
        maximumItems: 4,
        maximumLength: 80,
      ),
    );
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
