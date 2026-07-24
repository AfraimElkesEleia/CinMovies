import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/movie_details/data/movie_details_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeAdapter adapter;
  late MovieDetailsRepository repository;

  setUp(() {
    dotenv.loadFromString(envString: 'TMDB_API_KEY=test-token');
    adapter = _FakeAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.themoviedb.org/3'))
      ..httpClientAdapter = adapter;
    repository = MovieDetailsRepository(dio);
  });

  test('fetchMovieDetails sends bearer auth and maps full details', () async {
    adapter.responseJson = {
      'id': 10,
      'title': 'Full Movie',
      'backdrop_path': '/backdrop.jpg',
      'release_date': '2024-05-01',
      'runtime': 142,
      'vote_average': 8.2,
      'vote_count': 12500,
      'overview': 'Full overview',
      'genres': [
        {'id': 28, 'name': 'Action'},
      ],
      'credits': {
        'crew': [
          {'job': 'Director', 'name': 'Jane Director'},
        ],
        'cast': [
          {
            'name': 'Actor One',
            'character': 'Hero',
            'profile_path': '/actor.jpg',
          },
        ],
      },
      'reviews': {
        'results': [
          {
            'author': 'critic',
            'content': 'Great',
            'created_at': '2024-06-01T00:00:00.000Z',
            'author_details': {'username': 'critic_user', 'rating': 8},
          },
        ],
      },
      'similar': {
        'results': [
          {'id': 11, 'title': 'Similar Movie'},
        ],
      },
    };

    final result = await repository.fetchMovieDetails(_seed());

    expect(result.isRight(), isTrue);
    final details = result.getOrElse(
      () => throw StateError('Expected details'),
    );
    expect(details.movie.title, 'Full Movie');
    expect(details.movie.imageAsset, 'https://image.tmdb.org/t/p/w500/backdrop.jpg');
    expect(details.movie.genres, ['Action']);
    expect(details.movie.duration, '2h 22m');
    expect(details.movie.director, 'Jane Director');
    expect(details.movie.cast.single.name, 'Actor One');
    expect(details.movie.reviews.single.username, 'critic_user');
    expect(details.similarMovies.single.title, 'Similar Movie');
    expect(adapter.lastOptions?.path, '/movie/10');
    expect(adapter.lastOptions?.headers['Authorization'], 'Bearer test-token');
    expect(
      adapter.lastOptions?.queryParameters['append_to_response'],
      'credits,reviews,similar,videos',
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

Movie _seed() {
  return const Movie(
    id: '10',
    title: 'Seed',
    imageAsset: 'assets/images/movie_ex1.jpg',
    genres: [],
    rating: 7,
    year: '2024',
    duration: 'N/A',
    ageRating: 'NR',
    synopsis: 'Seed synopsis',
    director: 'Unknown',
    votes: '1K',
    availability: MovieAvailability.streaming,
    cast: [],
    reviews: [],
  );
}
