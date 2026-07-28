import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class EnvConfig {
  static const defaultGeminiModel = 'gemini-3.5-flash-lite';

  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } on Object catch (error) {
      throw StateError(
        'Could not load .env. Copy .env.example to .env and add the required '
        'values. Details: $error',
      );
    }

    for (final key in _requiredKeys) {
      _required(key);
    }
    supabasePublishableKey;
  }

  static String get supabaseUrl => _required('SUPABASE_URL');

  static String get supabasePublishableKey {
    final publishableKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY']?.trim();
    if (publishableKey != null && publishableKey.isNotEmpty) {
      return publishableKey;
    }
    return _required('SUPABASE_ANON_KEY');
  }

  static String get tmdbAccessToken => _required('TMDB_API_KEY');

  static String get geminiApiKey => _required('GEMINI_API_KEY');

  static String get geminiModel {
    final value = dotenv.env['GEMINI_MODEL']?.trim();
    return value == null || value.isEmpty ? defaultGeminiModel : value;
  }

  static const _requiredKeys = <String>[
    'SUPABASE_URL',
    'TMDB_API_KEY',
    'GEMINI_API_KEY',
  ];

  static String _required(String key) {
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing required environment value: $key. '
        'Add it to the project root .env file.',
      );
    }
    return value;
  }
}
