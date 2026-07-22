import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';
import 'package:cinmovies_app/features/profile/data/profile_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ProfileStatus { initial, loading, loaded, failure }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.fullName = 'Movie Explorer',
    this.username,
    this.avatarUrl,
    this.watchedCount = 0,
    this.watchlistCount = 0,
  });

  final ProfileStatus status;
  final String fullName;
  final String? username;
  final String? avatarUrl;
  final int watchedCount;
  final int watchlistCount;

  int get reviewCount => 0;

  @override
  List<Object?> get props => [
        status,
        fullName,
        username,
        avatarUrl,
        watchedCount,
        watchlistCount,
      ];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._profileRepository, this._libraryRepository, this._authRepository)
      : super(const ProfileState());

  final ProfileRepository _profileRepository;
  final LibraryRepository _libraryRepository;
  final AuthRepository _authRepository;

  Future<void> load() async {
    emit(const ProfileState(status: ProfileStatus.loading));
    try {
      final profile = await _profileRepository.currentProfile();
      final counts = await Future.wait([
        _libraryRepository.count(UserMovieListType.watched),
        _libraryRepository.count(UserMovieListType.watchlist),
      ]);

      final fullName = profile?['full_name'] as String?;
      emit(
        ProfileState(
          status: ProfileStatus.loaded,
          fullName: fullName?.trim().isNotEmpty == true
              ? fullName!
              : 'Movie Explorer',
          username: profile?['username'] as String?,
          avatarUrl: profile?['avatar_url'] as String?,
          watchedCount: counts[0],
          watchlistCount: counts[1],
        ),
      );
    } catch (_) {
      emit(const ProfileState(status: ProfileStatus.failure));
    }
  }

  Future<void> logout() => _authRepository.signOut();
}
