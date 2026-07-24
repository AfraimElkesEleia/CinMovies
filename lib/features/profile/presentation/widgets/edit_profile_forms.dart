import 'dart:typed_data';

import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/core/widgets/app_text_field.dart';
import 'package:cinmovies_app/features/login/presentation/widgets/login_primary_button.dart';
import 'package:cinmovies_app/features/login/presentation/widgets/login_styles.dart';
import 'package:cinmovies_app/features/profile/presentation/cubit/profile_edit_cubit.dart';
import 'package:cinmovies_app/features/profile/presentation/widgets/edit_profile_avatar.dart';
import 'package:flutter/material.dart';

class EditProfileForms extends StatelessWidget {
  const EditProfileForms({
    super.key,
    required this.state,
    required this.profileFormKey,
    required this.passwordFormKey,
    required this.fullNameController,
    required this.usernameController,
    required this.bioController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.profileImageBytes,
    required this.onPickProfileImage,
    required this.onRemoveProfileImage,
    required this.onSaveProfile,
    required this.onChangePassword,
    required this.requiredValidator,
    required this.passwordValidator,
    required this.confirmPasswordValidator,
  });

  final ProfileEditState state;
  final GlobalKey<FormState> profileFormKey;
  final GlobalKey<FormState> passwordFormKey;
  final TextEditingController fullNameController;
  final TextEditingController usernameController;
  final TextEditingController bioController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final Uint8List? profileImageBytes;
  final VoidCallback onPickProfileImage;
  final VoidCallback onRemoveProfileImage;
  final VoidCallback onSaveProfile;
  final VoidCallback onChangePassword;
  final FormFieldValidator<String> requiredValidator;
  final FormFieldValidator<String> passwordValidator;
  final FormFieldValidator<String> confirmPasswordValidator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Form(
          key: profileFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: EditableAvatar(
                  imageBytes: profileImageBytes,
                  avatarUrl: state.avatarUrl,
                  isLoading: state.isLoading,
                  onPick: onPickProfileImage,
                  onRemove: onRemoveProfileImage,
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: 'Full Name',
                hintText: 'John Doe',
                prefixIcon: Icons.person_outline,
                controller: fullNameController,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                validator: requiredValidator,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Username',
                hintText: 'movie_fan',
                prefixIcon: Icons.alternate_email,
                controller: usernameController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Bio',
                hintText: 'A short note about your taste',
                prefixIcon: Icons.badge_outlined,
                controller: bioController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 22),
              LoginPrimaryButton(
                text: state.isLoading ? 'Saving...' : 'Save Personal Info',
                onPressed: state.isLoading ? null : onSaveProfile,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const _SectionTitle(title: 'Change Password'),
        const SizedBox(height: 14),
        Form(
          key: passwordFormKey,
          child: Column(
            children: [
              AppTextField(
                label: 'New Password',
                hintText: 'Enter new password',
                prefixIcon: Icons.lock_outline,
                controller: passwordController,
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: passwordValidator,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Confirm New Password',
                hintText: 'Confirm new password',
                prefixIcon: Icons.lock_reset,
                controller: confirmPasswordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: confirmPasswordValidator,
                onSubmitted: (_) => onChangePassword(),
              ),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: state.isLoading ? null : onChangePassword,
                icon: const Icon(Icons.password_rounded),
                label: const Text('Update Password'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: LoginStyles.primaryColor,
                  side: BorderSide(
                    color: LoginStyles.primaryColor.withValues(alpha: 0.6),
                  ),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
