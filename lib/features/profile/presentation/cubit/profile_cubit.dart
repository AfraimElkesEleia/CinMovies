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
    this.email,
    this.bio,
    this.avatarUrl,
    this.watchedCount = 0,
    this.watchlistCount = 0,
  });

  final ProfileStatus status;
  final String fullName;
  final String? username;
  final String? email;
  final String? bio;
  final String? avatarUrl;
  final int watchedCount;
  final int watchlistCount;

  int get reviewCount => 0;

  @override
  List<Object?> get props => [
        status,
        fullName,
        username,
        email,
        bio,
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
      final profileResult = await _profileRepository.currentProfile();
      final countResults = await Future.wait([
        _libraryRepository.count(UserMovieListType.watched),
        _libraryRepository.count(UserMovieListType.watchlist),
      ]);

      // If profile fetch failed, emit failure.
      if (profileResult.isLeft()) {
        emit(const ProfileState(status: ProfileStatus.failure));
        return;
      }

      // If any count failed, emit failure.
      for (final result in countResults) {
        if (result.isLeft()) {
          emit(const ProfileState(status: ProfileStatus.failure));
          return;
        }
      }

      final profile = profileResult.getOrElse(() => null);
      final fullName = profile?['full_name'] as String?;
      emit(
        ProfileState(
          status: ProfileStatus.loaded,
          fullName: fullName?.trim().isNotEmpty == true
              ? fullName!
              : 'Movie Explorer',
          username: profile?['username'] as String?,
          email: _authRepository.currentUser?.email,
          bio: profile?['bio'] as String?,
          avatarUrl: profile?['avatar_url'] as String?,
          watchedCount: countResults[0].getOrElse(() => 0),
          watchlistCount: countResults[1].getOrElse(() => 0),
        ),
      );
    } catch (_) {
      emit(const ProfileState(status: ProfileStatus.failure));
    }
  }

  Future<void> logout() => _authRepository.signOut();
}
