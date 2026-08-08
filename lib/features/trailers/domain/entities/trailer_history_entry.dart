import 'package:equatable/equatable.dart';

class TrailerHistoryEntry extends Equatable {
  const TrailerHistoryEntry({
    required this.videoKey,
    required this.movieId,
    required this.title,
    required this.imageAsset,
    required this.watchedSeconds,
    required this.totalSeconds,
    required this.updatedAt,
  });

  factory TrailerHistoryEntry.fromMap(Map<String, dynamic> map) {
    final updatedAtValue = map['updated_at'];
    final updatedAt = updatedAtValue is int
        ? DateTime.fromMillisecondsSinceEpoch(updatedAtValue, isUtc: true)
        : DateTime.tryParse(updatedAtValue?.toString() ?? '')?.toUtc();

    return TrailerHistoryEntry(
      videoKey: (map['video_key'] as String? ?? '').trim(),
      movieId: (map['movie_id'] as String? ?? '').trim(),
      title: (map['title'] as String? ?? 'Untitled trailer').trim(),
      imageAsset:
          (map['image_asset'] as String? ?? 'assets/images/app_logo.png').trim(),
      watchedSeconds: ((map['watched_seconds'] as num?) ?? 0).toInt(),
      totalSeconds: ((map['total_seconds'] as num?) ?? 0).toInt(),
      updatedAt: updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    ).normalized();
  }

  final String videoKey;
  final String movieId;
  final String title;
  final String imageAsset;
  final int watchedSeconds;
  final int totalSeconds;
  final DateTime updatedAt;

  double get progress {
    if (totalSeconds <= 0) return 0;
    return (watchedSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  int get percentage => (progress * 100).round().clamp(0, 100);

  bool get isComplete => totalSeconds > 0 && progress >= 0.95;

  TrailerHistoryEntry normalized() {
    final safeTotal = totalSeconds < 0 ? 0 : totalSeconds;
    final safeWatched = watchedSeconds.clamp(0, safeTotal);
    return TrailerHistoryEntry(
      videoKey: videoKey,
      movieId: movieId,
      title: title.isEmpty ? 'Untitled trailer' : title,
      imageAsset: imageAsset.isEmpty
          ? 'assets/images/app_logo.png'
          : imageAsset,
      watchedSeconds: safeWatched,
      totalSeconds: safeTotal,
      updatedAt: updatedAt.toUtc(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'video_key': videoKey,
      'movie_id': movieId,
      'title': title,
      'image_asset': imageAsset,
      'watched_seconds': watchedSeconds,
      'total_seconds': totalSeconds,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  @override
  List<Object> get props => [
    videoKey,
    movieId,
    title,
    imageAsset,
    watchedSeconds,
    totalSeconds,
    updatedAt,
  ];
}
