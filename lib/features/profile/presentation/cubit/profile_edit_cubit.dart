import 'dart:typed_data';

import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:cinmovies_app/features/profile/data/profile_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ProfileEditStatus { initial, loading, loaded, saving, success, failure }

class ProfileEditState extends Equatable {
  const ProfileEditState({
    this.status = ProfileEditStatus.initial,
    this.fullName = '',
    this.username,
    this.bio,
    this.avatarUrl,
    this.errorMessage,
  });

  final ProfileEditStatus status;
  final String fullName;
  final String? username;
  final String? bio;
  final String? avatarUrl;
  final String? errorMessage;

  bool get isLoading =>
      status == ProfileEditStatus.loading || status == ProfileEditStatus.saving;

  ProfileEditState copyWith({
    ProfileEditStatus? status,
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? errorMessage,
    bool clearUsername = false,
    bool clearBio = false,
    bool clearError = false,
  }) {
    return ProfileEditState(
      status: status ?? this.status,
      fullName: fullName ?? this.fullName,
      username: clearUsername ? null : username ?? this.username,
      bio: clearBio ? null : bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        fullName,
        username,
        bio,
        avatarUrl,
        errorMessage,
      ];
}

class ProfileEditCubit extends Cubit<ProfileEditState> {
  ProfileEditCubit(this._profileRepository, this._authRepository)
      : super(const ProfileEditState());

  final ProfileRepository _profileRepository;
  final AuthRepository _authRepository;

  Future<void> load() async {
    emit(state.copyWith(status: ProfileEditStatus.loading, clearError: true));

    final result = await _profileRepository.currentProfile();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ProfileEditStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (profile) => emit(
        ProfileEditState(
          status: ProfileEditStatus.loaded,
          fullName: (profile?['full_name'] as String?) ?? '',
          username: profile?['username'] as String?,
          bio: profile?['bio'] as String?,
          avatarUrl: profile?['avatar_url'] as String?,
        ),
      ),
    );
  }

  Future<void> saveProfile({
    required String fullName,
    required String username,
    required String bio,
    Uint8List? avatarBytes,
    String? avatarFileName,
    String? avatarContentType,
  }) async {
    emit(state.copyWith(status: ProfileEditStatus.saving, clearError: true));

    String? avatarUrl;
    if (avatarBytes != null) {
      final uploadResult = await _profileRepository.uploadAvatar(
        bytes: avatarBytes,
        fileName: avatarFileName ?? 'profile-image.jpg',
        contentType: avatarContentType,
      );

      if (uploadResult.isLeft()) {
        uploadResult.fold(
          (failure) => emit(
            state.copyWith(
              status: ProfileEditStatus.failure,
              errorMessage: failure.message,
            ),
          ),
          (_) {},
        );
        return;
      }

      avatarUrl = uploadResult.getOrElse(() => '');
    }

    final trimmedUsername = username.trim();
    final trimmedBio = bio.trim();
    final updateResult = await _profileRepository.updateProfile(
      fullName: fullName.trim(),
      username: trimmedUsername.isEmpty ? null : trimmedUsername,
      bio: trimmedBio.isEmpty ? null : trimmedBio,
      avatarUrl: avatarUrl,
      clearUsername: trimmedUsername.isEmpty,
      clearBio: trimmedBio.isEmpty,
    );

    updateResult.fold(
      (failure) => emit(
        state.copyWith(
          status: ProfileEditStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: ProfileEditStatus.success,
          fullName: fullName.trim(),
          username: trimmedUsername,
          bio: trimmedBio,
          avatarUrl: avatarUrl,
          clearUsername: trimmedUsername.isEmpty,
          clearBio: trimmedBio.isEmpty,
        ),
      ),
    );
  }

  Future<void> changePassword(String password) async {
    emit(state.copyWith(status: ProfileEditStatus.saving, clearError: true));
    final result = await _authRepository.updatePassword(password);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ProfileEditStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(state.copyWith(status: ProfileEditStatus.success)),
    );
  }
}
