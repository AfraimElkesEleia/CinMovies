import 'package:equatable/equatable.dart';

final class UserProfile extends Equatable {
  const UserProfile({
    required this.fullName,
    this.username,
    this.bio,
    this.avatarUrl,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      fullName: map['full_name'] as String? ?? '',
      username: map['username'] as String?,
      bio: map['bio'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  final String fullName;
  final String? username;
  final String? bio;
  final String? avatarUrl;

  @override
  List<Object?> get props => [fullName, username, bio, avatarUrl];
}
