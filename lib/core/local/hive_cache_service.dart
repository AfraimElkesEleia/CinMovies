import 'package:hive_flutter/hive_flutter.dart';

class HiveCacheService {
  HiveCacheService(
    this._searchBox,
    this._movieBox,
    this._userSnapshotBox,
    this._favoriteGenresBox,
  );

  static const searchBoxName = 'search_cache';
  static const movieBoxName = 'movie_cache';
  static const userSnapshotBoxName = 'user_snapshot_cache';
  static const favoriteGenresBoxName = 'favorite_genres_cache';

  final Box<dynamic> _searchBox;
  final Box<dynamic> _movieBox;
  final Box<dynamic> _userSnapshotBox;
  final Box<dynamic> _favoriteGenresBox;

  static Future<HiveCacheService> initialize() async {
    await Hive.initFlutter();
    final searchBox = await Hive.openBox<dynamic>(searchBoxName);
    final movieBox = await Hive.openBox<dynamic>(movieBoxName);
    final userSnapshotBox = await Hive.openBox<dynamic>(userSnapshotBoxName);
    final favoriteGenresBox = await Hive.openBox<dynamic>(favoriteGenresBoxName);

    return HiveCacheService(
      searchBox,
      movieBox,
      userSnapshotBox,
      favoriteGenresBox,
    );
  }

  List<String> getRecentSearches() {
    return _stringList(_searchBox.get('recent_searches'));
  }

  Future<void> saveRecentSearch(String query, {int limit = 6}) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;

    final searches = [
      normalized,
      ...getRecentSearches().where(
        (item) => item.toLowerCase() != normalized.toLowerCase(),
      ),
    ].take(limit).toList();

    await _searchBox.put('recent_searches', searches);
  }

  Future<void> deleteRecentSearch(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;

    final searches = getRecentSearches()
        .where((item) => item.toLowerCase() != normalized.toLowerCase())
        .toList();

    await _searchBox.put('recent_searches', searches);
  }

  Future<void> cacheMovie(String id, Map<String, dynamic> row) async {
    await _movieBox.put(id, row);
  }

  Map<String, dynamic>? getCachedMovie(String id) {
    return _map(_movieBox.get(id));
  }

  Future<void> cacheUserSnapshot(String key, Object value) async {
    await _userSnapshotBox.put(key, value);
  }

  T? getUserSnapshot<T>(String key) {
    final value = _userSnapshotBox.get(key);
    return value is T ? value : null;
  }

  Set<String> getFavoriteGenres() {
    return _stringList(_favoriteGenresBox.get('genres')).toSet();
  }

  Future<void> cacheFavoriteGenres(Set<String> genres) async {
    await _favoriteGenresBox.put('genres', genres.toList()..sort());
  }

  List<String> _stringList(dynamic value) {
    if (value is! Iterable) return const [];
    return value.whereType<String>().toList();
  }

  Map<String, dynamic>? _map(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
