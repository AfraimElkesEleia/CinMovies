import 'package:flutter/material.dart';

class LibraryMovieModel {
  const LibraryMovieModel({
    required this.title,
    required this.imageAsset,
    required this.genre,
    required this.year,
    required this.duration,
    required this.status,
    required this.progress,
    required this.actionIcon,
  });

  final String title;
  final String imageAsset;
  final String genre;
  final String year;
  final String duration;
  final String status;
  final double progress;
  final IconData actionIcon;
}
