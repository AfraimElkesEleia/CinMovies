import 'package:equatable/equatable.dart';

class BrowseGenre extends Equatable {
  const BrowseGenre({required this.name, this.id});

  static const all = BrowseGenre(name: 'All');

  final String name;
  final int? id;

  bool get isAll => id == null && name == 'All';

  @override
  List<Object?> get props => [name, id];
}
