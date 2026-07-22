import 'package:cinmovies_app/core/local/hive_cache_service.dart';
import 'package:cinmovies_app/core/local/local_preferences_service.dart';
import 'package:cinmovies_app/core/supabase/supabase_database_service.dart';

class PreferenceRepository {
  const PreferenceRepository(this._database, this._cache, this._preferences);

  final SupabaseDatabaseService _database;
  final HiveCacheService _cache;
  final LocalPreferencesService _preferences;

  String get _userId {
    final id = _database.currentUser?.id;
    if (id == null) throw StateError('No authenticated user.');
    return id;
  }

  Set<String> cachedFavoriteGenres() => _cache.getFavoriteGenres();

  Future<void> saveSelectedGenres(Set<String> genreNames) async {
    await _cache.cacheFavoriteGenres(genreNames);
    await _preferences.setHasPassedOnboarding(true);
    await syncCachedFavoriteGenres();
  }

  Future<void> syncCachedFavoriteGenres() async {
    final genreNames = _cache.getFavoriteGenres();
    if (genreNames.isEmpty) return;

    final genres = await _database
        .from('genres')
        .select('id, name')
        .inFilter('name', genreNames.toList());

    await _database.from('user_genre_preferences').delete().eq('user_id', _userId);

    final rows = genres
        .map<Map<String, dynamic>>(
          (genre) => {'user_id': _userId, 'genre_id': genre['id']},
        )
        .toList();

    if (rows.isNotEmpty) {
      await _database.from('user_genre_preferences').insert(rows);
    }

    await _database
        .from('profiles')
        .update({'onboarding_completed': true})
        .eq('id', _userId);
  }
}
