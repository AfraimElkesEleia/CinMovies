import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/features/trailers/data/trailer_history_repository.dart';
import 'package:cinmovies_app/features/trailers/domain/entities/trailer_history_entry.dart';
import 'package:cinmovies_app/features/trailers/presentation/cubit/trailer_playback_cubit.dart';
import 'package:cinmovies_app/features/trailers/presentation/model/trailer_viewer_args.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saves changed playback progress on the five second interval', () async {
    final repository = _FakeTrailerHistoryRepository();
    final cubit = TrailerPlaybackCubit(repository, _args);
    addTearDown(cubit.close);
    await cubit.initialize();

    cubit.updateProgress(
      const Duration(seconds: 12),
      const Duration(seconds: 100),
    );
    expect(repository.saved, isEmpty);

    await Future<void>.delayed(
      TrailerPlaybackCubit.saveInterval + const Duration(milliseconds: 150),
    );

    expect(repository.saved, hasLength(1));
    expect(repository.saved.single.watchedSeconds, 12);
    expect(repository.saved.single.totalSeconds, 100);
  });

  test('completed trailer resumes from zero and completion saves 100%', () async {
    final repository = _FakeTrailerHistoryRepository(
      existing: _entry(watched: 96),
    );
    final cubit = TrailerPlaybackCubit(repository, _args);
    addTearDown(cubit.close);

    await cubit.initialize();
    expect(cubit.state.initialSeconds, 0);

    await cubit.markCompleted(const Duration(seconds: 100));
    expect(repository.saved.single.watchedSeconds, 100);
    expect(repository.saved.single.percentage, 100);
  });

  test('incomplete trailer resumes at its saved second', () async {
    final repository = _FakeTrailerHistoryRepository(
      existing: _entry(watched: 42),
    );
    final cubit = TrailerPlaybackCubit(repository, _args);
    addTearDown(cubit.close);

    await cubit.initialize();

    expect(cubit.state.status, TrailerPlaybackStatus.ready);
    expect(cubit.state.initialSeconds, 42);
  });
}

const _args = TrailerViewerArgs(
  videoKey: 'video-key',
  movieId: '10',
  title: 'Movie Trailer',
  imageAsset: 'assets/images/movie_ex1.jpg',
);

TrailerHistoryEntry _entry({required int watched}) {
  return TrailerHistoryEntry(
    videoKey: _args.videoKey,
    movieId: _args.movieId,
    title: _args.title,
    imageAsset: _args.imageAsset,
    watchedSeconds: watched,
    totalSeconds: 100,
    updatedAt: DateTime.utc(2026),
  );
}

class _FakeTrailerHistoryRepository
    implements TrailerHistoryRepositoryContract {
  _FakeTrailerHistoryRepository({this.existing});

  final TrailerHistoryEntry? existing;
  final List<TrailerHistoryEntry> saved = [];

  @override
  Future<Either<Failure, TrailerHistoryEntry?>> findByVideoKey(
    String videoKey,
  ) async {
    return Right(existing);
  }

  @override
  Future<Either<Failure, List<TrailerHistoryEntry>>> history() async {
    return Right(existing == null ? const [] : [existing!]);
  }

  @override
  Future<Either<Failure, void>> saveProgress(
    TrailerHistoryEntry entry,
  ) async {
    saved.add(entry);
    return const Right(null);
  }

  @override
  Stream<List<TrailerHistoryEntry>> watchHistory() {
    return Stream.value(existing == null ? const [] : [existing!]);
  }
}
