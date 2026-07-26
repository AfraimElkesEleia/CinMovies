import 'package:equatable/equatable.dart';

class TrailerViewerArgs extends Equatable {
  const TrailerViewerArgs({
    required this.videoKey,
    required this.movieId,
    required this.title,
    required this.imageAsset,
  });

  final String videoKey;
  final String movieId;
  final String title;
  final String imageAsset;

  @override
  List<Object> get props => [videoKey, movieId, title, imageAsset];
}
