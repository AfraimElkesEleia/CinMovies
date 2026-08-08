import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/core/local/hive_cache_service.dart';
import 'package:cinmovies_app/features/trailers/domain/entities/trailer_history_entry.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class TrailerHistoryRepositoryContract {
  Future<Either<Failure, List<TrailerHistoryEntry>>> history();

  Future<Either<Failure, TrailerHistoryEntry?>> findByVideoKey(String videoKey);

  Future<Either<Failure, void>> saveProgress(TrailerHistoryEntry entry);

  Future<Either<Failure, void>> remove(String videoKey);

  Stream<List<TrailerHistoryEntry>> watchHistory();
}

class TrailerHistoryRepository implements TrailerHistoryRepositoryContract {
  TrailerHistoryRepository(
    this._cache,
    this._supabase, {
    this._scopeIdResolver,
  });

  final HiveCacheService _cache;
  final SupabaseClient _supabase;
  final String Function()? _scopeIdResolver;

  String get _scopeId {
    return _scopeIdResolver?.call() ??
        _supabase.auth.currentUser?.id ??
        'guest';
  }

  @override
  Future<Either<Failure, List<TrailerHistoryEntry>>> history() async {
    try {
      return Right(await _historyForScope(_scopeId));
    } catch (error) {
      return Left(mapError(error));
    }
  }

  @override
  Future<Either<Failure, TrailerHistoryEntry?>> findByVideoKey(
    String videoKey,
  ) async {
    try {
      final key = videoKey.trim();
      if (key.isEmpty) return const Right(null);
      final map = _cache.getTrailerHistoryEntry(_scopeId, key);
      if (map == null) return const Right(null);
      final entry = _tryParse(map);
      return Right(
        entry != null && entry.videoKey.isNotEmpty && entry.totalSeconds > 0
            ? entry
            : null,
      );
    } catch (error) {
      return Left(mapError(error));
    }
  }

  @override
  Future<Either<Failure, void>> saveProgress(TrailerHistoryEntry entry) async {
    try {
      final normalized = entry.normalized();
      if (normalized.videoKey.isEmpty || normalized.totalSeconds <= 0) {
        return const Right(null);
      }
      await _cache.cacheTrailerHistoryEntry(
        _scopeId,
        normalized.videoKey,
        normalized.toMap(),
      );
      return const Right(null);
    } catch (error) {
      return Left(mapError(error));
    }
  }

  @override
  Future<Either<Failure, void>> remove(String videoKey) async {
    try {
      final key = videoKey.trim();
      if (key.isEmpty) return const Right(null);
      await _cache.deleteTrailerHistoryEntry(_scopeId, key);
      return const Right(null);
    } catch (error) {
      return Left(mapError(error));
    }
  }

  @override
  Stream<List<TrailerHistoryEntry>> watchHistory() async* {
    final scopeId = _scopeId;
    yield await _historyForScope(scopeId);
    await for (final _ in _cache.watchTrailerHistory(scopeId)) {
      yield await _historyForScope(scopeId);
    }
  }

  Future<List<TrailerHistoryEntry>> _historyForScope(String scopeId) async {
    try {
      final entries =
          _cache
              .getTrailerHistory(scopeId)
              .map(_tryParse)
              .whereType<TrailerHistoryEntry>()
              .where(
                (entry) => entry.videoKey.isNotEmpty && entry.totalSeconds > 0,
              )
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return entries;
    } catch (_) {
      return const [];
    }
  }

  TrailerHistoryEntry? _tryParse(Map<String, dynamic> map) {
    try {
      return TrailerHistoryEntry.fromMap(map);
    } catch (_) {
      return null;
    }
  }
}
