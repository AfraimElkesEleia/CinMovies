import 'package:cinmovies_app/core/error/app_error.dart';
import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';
import 'package:cinmovies_app/features/profile/data/profile_repository.dart';
import 'package:cinmovies_app/features/reviews/data/review_repository.dart';
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
    this.favoriteCount = 0,
    this.watchlistCount = 0,
    this.reviewCount = 0,
    this.failure,
  });

  final ProfileStatus status;
  final String fullName;
  final String? username;
  final String? email;
  final String? bio;
  final String? avatarUrl;
  final int favoriteCount;
  final int watchlistCount;
  final int reviewCount;
  final AppError? failure;

  @override
  List<Object?> get props => [
    status,
    fullName,
    username,
    email,
    bio,
    avatarUrl,
    favoriteCount,
    watchlistCount,
    reviewCount,
    failure,
  ];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(
    this._profileRepository,
    this._libraryRepository,
    this._authRepository,
    this._reviewRepository,
  ) : super(const ProfileState());

  final ProfileRepository _profileRepository;
  final LibraryRepository _libraryRepository;
  final AuthRepository _authRepository;
  final ReviewRepository _reviewRepository;

  Future<void> load() async {
    emit(const ProfileState(status: ProfileStatus.loading));
    final profileFuture = _profileRepository.currentProfile();
    final favoriteCountFuture = _libraryRepository.count(
      UserMovieListType.favorite,
    );
    final watchlistCountFuture = _libraryRepository.count(
      UserMovieListType.watchlist,
    );
    final reviewCountFuture = _reviewRepository.countForCurrentUser();

    final profileResult = await profileFuture;
    final favoriteCountResult = await favoriteCountFuture;
    final watchlistCountResult = await watchlistCountFuture;
    final reviewCountResult = await reviewCountFuture;
    final failure =
        profileResult.errorOrNull ??
        favoriteCountResult.errorOrNull ??
        watchlistCountResult.errorOrNull ??
        reviewCountResult.errorOrNull;
    if (failure != null) {
      emit(ProfileState(status: ProfileStatus.failure, failure: failure));
      return;
    }

    final profile = profileResult.getOrNull();
    emit(
      ProfileState(
        status: ProfileStatus.loaded,
        fullName: profile?.fullName.trim().isNotEmpty == true
            ? profile!.fullName
            : 'Movie Explorer',
        username: profile?.username,
        email: _authRepository.currentUserEmail,
        bio: profile?.bio,
        avatarUrl: profile?.avatarUrl,
        favoriteCount: favoriteCountResult.getOrElse(() => 0),
        watchlistCount: watchlistCountResult.getOrElse(() => 0),
        reviewCount: reviewCountResult.getOrElse(() => 0),
      ),
    );
  }

  Future<bool> logout() async {
    final result = await _authRepository.signOut();
    return result.when(
      onSuccess: (_) => true,
      onFailure: (error) {
        emit(ProfileState(status: ProfileStatus.failure, failure: error));
        return false;
      },
    );
  }
}
