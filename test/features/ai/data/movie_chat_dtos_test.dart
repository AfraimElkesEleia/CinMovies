import 'package:cinmovies_app/features/ai/data/models/movie_chat_dtos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MovieChatMessageDto', () {
    test('parses canonical movie cards and optional suggested replies', () {
      final message = MovieChatMessageDto.fromJson(_validMessage).value;

      expect(message.content, 'These fit your request.');
      expect(message.suggestedReplies, ['Something lighter']);
      final recommendation = message.recommendations.single;
      expect(recommendation.movie.id, '157336');
      expect(recommendation.movie.title, 'Interstellar');
      expect(
        recommendation.movie.imageAsset,
        'https://image.tmdb.org/t/p/w500/poster.jpg',
      );
      expect(recommendation.movie.year, '2014');
      expect(recommendation.movie.duration, '2h 49m');
      expect(recommendation.reason, 'Grounded reason');
    });

    test('drops malformed movie cards without losing assistant text', () {
      final message = MovieChatMessageDto.fromJson({
        ..._validMessage,
        'movies': [
          ...(_validMessage['movies']! as List<Object?>),
          {'movie': 'invalid', 'reason': 'Bad'},
          {
            'movie': {'id': null},
            'reason': '',
          },
        ],
      }).value;

      expect(message.content, 'These fit your request.');
      expect(message.recommendations, hasLength(1));
    });

    test('maps normalized Supabase movie relations to canonical Movie', () {
      final message = MovieChatMessageDto.fromDatabaseRow({
        'id': '7a324a71-e660-43d0-a2e6-b6f31437ecab',
        'role': 'assistant',
        'content': 'Database answer',
        'created_at': '2026-07-28T12:00:01Z',
        'suggested_replies': ['Compare them'],
        'ai_message_movies': [
          {
            'rank': 0,
            'reason': 'A thoughtful space adventure.',
            'movies': {
              'tmdb_id': 157336,
              'title': 'Interstellar',
              'poster_path': '/poster.jpg',
              'release_date': '2014-11-05',
              'runtime_minutes': 169,
              'vote_average': 8.7,
              'vote_count': 35000,
              'overview': 'Explorers travel through a wormhole.',
              'movie_genres': [
                {
                  'genres': {'name': 'Science Fiction'},
                },
              ],
            },
          },
        ],
      }).value;

      expect(message.recommendations.single.movie.id, '157336');
      expect(message.recommendations.single.movie.genres, ['Science Fiction']);
      expect(message.recommendations.single.reason, contains('space'));
    });

    test('rejects a completely invalid message', () {
      expect(
        () => MovieChatMessageDto.fromJson({'content': 'bad'}),
        throwsFormatException,
      );
    });
  });
}

const _validMessage = <String, Object?>{
  'id': '7a324a71-e660-43d0-a2e6-b6f31437ecab',
  'role': 'assistant',
  'content': 'These fit your request.',
  'createdAt': '2026-07-28T12:00:01Z',
  'movies': [
    {
      'movie': {
        'id': 157336,
        'title': 'Interstellar',
        'poster_path': '/poster.jpg',
        'release_date': '2014-11-05',
        'runtime': 169,
        'age_rating': 'PG-13',
        'vote_average': 8.7,
        'vote_count': 35000,
        'overview': 'Explorers travel through a wormhole.',
        'genres': [
          {'id': 878, 'name': 'Science Fiction'},
        ],
      },
      'reason': 'Grounded reason',
    },
  ],
  'suggestedReplies': ['Something lighter'],
};
