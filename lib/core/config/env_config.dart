import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class EnvConfig {
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}
  }

  static String get supabaseUrl => _required('SUPABASE_URL');

  static String get supabasePublishableKey {
    return dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
        dotenv.env['SUPABASE_ANON_KEY'] ??
        _required('SUPABASE_PUBLISHABLE_KEY');
  }

  static String _required(String key) {
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) {
      throw StateError('Missing required environment value: $key');
    }
    return value;
  }
}
