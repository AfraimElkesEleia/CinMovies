import 'dart:typed_data';

import 'package:cinmovies_app/core/error/app_error.dart';
import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:cinmovies_app/features/profile/data/profile_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum EditProfileStatus { initial, loading, loaded, saving, success, failure }

class EditProfileState extends Equatable {
  const EditProfileState({
    this.status = EditProfileStatus.initial,
    this.fullName = '',
    this.username,
    this.bio,
    this.avatarUrl,
    this.failure,
  });

  final EditProfileStatus status;
  final String fullName;
  final String? username;
  final String? bio;
  final String? avatarUrl;
  final AppError? failure;

  bool get isLoading =>
      status == EditProfileStatus.loading || status == EditProfileStatus.saving;

  EditProfileState copyWith({
    EditProfileStatus? status,
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
    AppError? failure,
    bool clearUsername = false,
    bool clearBio = false,
    bool clearFailure = false,
  }) {
    return EditProfileState(
      status: status ?? this.status,
      fullName: fullName ?? this.fullName,
      username: clearUsername ? null : username ?? this.username,
      bio: clearBio ? null : bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    fullName,
    username,
    bio,
    avatarUrl,
    failure,
  ];
}

class EditProfileCubit extends Cubit<EditProfileState> {
  EditProfileCubit(this._profileRepository, this._authRepository)
    : super(const EditProfileState());

  final ProfileRepository _profileRepository;
  final AuthRepository _authRepository;

  Future<void> load() async {
    emit(state.copyWith(status: EditProfileStatus.loading, clearFailure: true));

    final result = await _profileRepository.currentProfile();
    result.when(
      onSuccess: (profile) => emit(
        EditProfileState(
          status: EditProfileStatus.loaded,
          fullName: profile?.fullName ?? '',
          username: profile?.username,
          bio: profile?.bio,
          avatarUrl: profile?.avatarUrl,
        ),
      ),
      onFailure: (error) => emit(
        state.copyWith(status: EditProfileStatus.failure, failure: error),
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
    emit(state.copyWith(status: EditProfileStatus.saving, clearFailure: true));

    String? avatarUrl;
    if (avatarBytes != null) {
      final uploadResult = await _profileRepository.uploadAvatar(
        bytes: avatarBytes,
        fileName: avatarFileName ?? 'profile-image.jpg',
        contentType: avatarContentType,
      );

      if (uploadResult.isFailure) {
        uploadResult.when(
          onSuccess: (_) {},
          onFailure: (error) => emit(
            state.copyWith(status: EditProfileStatus.failure, failure: error),
          ),
        );
        return;
      }

      avatarUrl = uploadResult.getOrNull() ?? '';
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

    updateResult.when(
      onSuccess: (_) => emit(
        state.copyWith(
          status: EditProfileStatus.success,
          fullName: fullName.trim(),
          username: trimmedUsername,
          bio: trimmedBio,
          avatarUrl: avatarUrl,
          clearUsername: trimmedUsername.isEmpty,
          clearBio: trimmedBio.isEmpty,
        ),
      ),
      onFailure: (error) => emit(
        state.copyWith(status: EditProfileStatus.failure, failure: error),
      ),
    );
  }

  Future<void> changePassword(String password) async {
    emit(state.copyWith(status: EditProfileStatus.saving, clearFailure: true));
    final result = await _authRepository.updatePassword(password);

    result.when(
      onSuccess: (_) => emit(state.copyWith(status: EditProfileStatus.success)),
      onFailure: (error) => emit(
        state.copyWith(status: EditProfileStatus.failure, failure: error),
      ),
    );
  }
}
