import 'package:cinmovies_app/core/constants/api_constants.dart';
import 'package:cinmovies_app/core/network/dio_client_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates a direct TMDB client with bearer authentication', () {
    final dio = DioClientFactory.createTmdb(accessToken: 'tmdb-test-token');

    expect(dio.options.baseUrl, ApiConstants.baseUrl);
    expect(
      dio.options.headers['Authorization'],
      'Bearer tmdb-test-token',
    );
  });

  test('creates a separate Gemini client with its API key header', () {
    final dio = DioClientFactory.createGemini(apiKey: 'gemini-test-key');

    expect(dio.options.baseUrl, ApiConstants.geminiBaseUrl);
    expect(dio.options.headers['x-goog-api-key'], 'gemini-test-key');
    expect(dio.options.headers['Authorization'], isNull);
  });
}
