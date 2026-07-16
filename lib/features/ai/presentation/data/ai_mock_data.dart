import 'package:flutter/material.dart';

class AiMovie {
  const AiMovie({
    required this.title,
    required this.imageAsset,
    required this.genres,
    required this.rating,
    required this.year,
    required this.duration,
    required this.synopsis,
  });

  final String title;
  final String imageAsset;
  final List<String> genres;
  final double rating;
  final String year;
  final String duration;
  final String synopsis;
}

class AiChatMessage {
  const AiChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.movies = const [],
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<AiMovie> movies;
}

class AiChatSession {
  const AiChatSession({
    required this.id,
    required this.title,
    required this.preview,
    required this.timestamp,
    required this.messages,
  });

  final String id;
  final String title;
  final String preview;
  final DateTime timestamp;
  final List<AiChatMessage> messages;
}

class AiMockData {
  const AiMockData._();

  static const suggestedPrompts = [
    'Best thrillers to watch tonight',
    'Top rated movies on CinMovies',
    'Something epic and action-packed',
    'Emotional drama recommendations',
    'Upcoming releases in 2026',
    'Short films under 2 hours',
  ];

  static const movies = [
    AiMovie(
      title: 'Avengers: Doomsday',
      imageAsset: 'assets/images/movie_ex1.jpg',
      genres: ['Action', 'Sci-Fi'],
      rating: 8.7,
      year: '2026',
      duration: '2h 24m',
      synopsis: 'A universe-level threat forces old and new heroes to unite.',
    ),
    AiMovie(
      title: 'Spider-Man: Brand New Day',
      imageAsset: 'assets/images/movie_ex2.jpg',
      genres: ['Adventure', 'Hero'],
      rating: 8.5,
      year: '2026',
      duration: '2h 8m',
      synopsis: 'Peter starts over while a new mystery pulls him back in.',
    ),
    AiMovie(
      title: 'Midnight Signal',
      imageAsset: 'assets/images/movie_ex1.jpg',
      genres: ['Thriller', 'Mystery'],
      rating: 8.2,
      year: '2025',
      duration: '1h 48m',
      synopsis: 'A late-night broadcast exposes secrets across the city.',
    ),
    AiMovie(
      title: 'Quiet Orbit',
      imageAsset: 'assets/images/movie_ex2.jpg',
      genres: ['Sci-Fi', 'Drama'],
      rating: 8.9,
      year: '2025',
      duration: '1h 56m',
      synopsis: 'An astronaut must choose between survival and truth.',
    ),
  ];

  static List<AiChatSession> initialSessions() {
    final now = DateTime.now();

    return [
      AiChatSession(
        id: 'h1',
        title: 'Sci-Fi Recommendations',
        preview: 'Great taste. These sci-fi picks mix scale and emotion.',
        timestamp: now.subtract(const Duration(hours: 3)),
        messages: [
          AiChatMessage(
            id: 'h1u',
            text: 'Recommend me some sci-fi movies',
            isUser: true,
            timestamp: now.subtract(const Duration(hours: 3)),
          ),
          AiChatMessage(
            id: 'h1a',
            text: 'Great taste. These sci-fi picks mix scale and emotion.',
            isUser: false,
            timestamp: now.subtract(const Duration(hours: 3, seconds: -2)),
            movies: movies
                .where((movie) => movie.genres.contains('Sci-Fi'))
                .toList(),
          ),
        ],
      ),
      AiChatSession(
        id: 'h2',
        title: 'Top Rated Films',
        preview: 'Here are the strongest rated movies in the catalog.',
        timestamp: now.subtract(const Duration(days: 1)),
        messages: [
          AiChatMessage(
            id: 'h2u',
            text: 'What are the best movies right now?',
            isUser: true,
            timestamp: now.subtract(const Duration(days: 1)),
          ),
          AiChatMessage(
            id: 'h2a',
            text: 'Here are the strongest rated movies in the catalog.',
            isUser: false,
            timestamp: now.subtract(const Duration(days: 1, seconds: -2)),
            movies: topRated(),
          ),
        ],
      ),
    ];
  }

  static ({String text, List<AiMovie> movies}) responseFor(String query) {
    final normalizedQuery = query.toLowerCase();

    if (_containsAny(normalizedQuery, ['thriller', 'suspense', 'mystery'])) {
      return (
        text:
            'Here are tense picks with mystery, momentum, and strong late-night energy.',
        movies: movies
            .where(
              (movie) =>
                  movie.genres.contains('Thriller') ||
                  movie.genres.contains('Mystery'),
            )
            .toList(),
      );
    }

    if (_containsAny(normalizedQuery, ['sci-fi', 'science', 'space', 'future'])) {
      return (
        text:
            'These sci-fi recommendations balance spectacle with smart story ideas.',
        movies: movies.where((movie) => movie.genres.contains('Sci-Fi')).toList(),
      );
    }

    if (_containsAny(normalizedQuery, ['action', 'adventure', 'epic'])) {
      return (
        text:
            'For a high-energy watch, start with these action and adventure picks.',
        movies: movies
            .where(
              (movie) =>
                  movie.genres.contains('Action') ||
                  movie.genres.contains('Adventure'),
            )
            .toList(),
      );
    }

    if (_containsAny(normalizedQuery, ['top', 'best', 'rated'])) {
      return (
        text: 'Here are the highest-rated movies available in your catalog.',
        movies: topRated(),
      );
    }

    return (
      text:
          'Based on the current catalog, these are flexible recommendations for your next watch.',
      movies: topRated(),
    );
  }

  static List<AiMovie> topRated() {
    final sorted = [...movies]..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(3).toList();
  }

  static bool _containsAny(String source, List<String> values) {
    return values.any(source.contains);
  }
}

String formatSessionTime(DateTime timestamp) {
  final diff = DateTime.now().difference(timestamp);

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  return '${diff.inDays} days ago';
}

String formatMessageTime(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}
