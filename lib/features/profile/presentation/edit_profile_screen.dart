import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/core/widgets/app_snack_bar.dart';
import 'package:cinmovies_app/core/widgets/app_text_field.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:cinmovies_app/features/login/presentation/widgets/login_primary_button.dart';
import 'package:cinmovies_app/features/login/presentation/widgets/login_styles.dart';
import 'package:cinmovies_app/features/profile/data/profile_repository.dart';
import 'package:cinmovies_app/features/profile/presentation/cubit/profile_edit_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileEditCubit(
        sl<ProfileRepository>(),
        sl<AuthRepository>(),
      )..load(),
      child: const _EditProfileView(),
    );
  }
}

class _EditProfileView extends StatefulWidget {
  const _EditProfileView();

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  static const _allowedImageContentTypes = {'image/jpeg', 'image/png'};
  static const _maxProfileImageBytes = 5 * 1024 * 1024;

  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _imagePicker = ImagePicker();

  Uint8List? _profileImageBytes;
  String? _profileImageName;
  String? _profileImageContentType;
  bool _hydrated = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileEditCubit, ProfileEditState>(
      listener: (context, state) {
        if (state.status == ProfileEditStatus.loaded && !_hydrated) {
          _fullNameController.text = state.fullName;
          _usernameController.text = state.username ?? '';
          _bioController.text = state.bio ?? '';
          _hydrated = true;
        }

        if (state.status == ProfileEditStatus.failure &&
            state.errorMessage != null) {
          AppSnackBar.showError(context, state.errorMessage!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: AppColors.scaffoldBackground,
            foregroundColor: AppColors.white,
            elevation: 0,
            title: const Text('Edit Profile'),
          ),
          body: SafeArea(
            child: state.status == ProfileEditStatus.loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: LoginStyles.primaryColor,
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Form(
                          key: _profileFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: _EditableAvatar(
                                  imageBytes: _profileImageBytes,
                                  avatarUrl: state.avatarUrl,
                                  isLoading: state.isLoading,
                                  onPick: _pickProfileImage,
                                  onRemove: _removeSelectedProfileImage,
                                ),
                              ),
                              const SizedBox(height: 24),
                              AppTextField(
                                label: 'Full Name',
                                hintText: 'John Doe',
                                prefixIcon: Icons.person_outline,
                                controller: _fullNameController,
                                keyboardType: TextInputType.name,
                                textInputAction: TextInputAction.next,
                                validator: _required,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: 'Username',
                                hintText: 'movie_fan',
                                prefixIcon: Icons.alternate_email,
                                controller: _usernameController,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: 'Bio',
                                hintText: 'A short note about your taste',
                                prefixIcon: Icons.badge_outlined,
                                controller: _bioController,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.done,
                              ),
                              const SizedBox(height: 22),
                              LoginPrimaryButton(
                                text: state.isLoading
                                    ? 'Saving...'
                                    : 'Save Personal Info',
                                onPressed:
                                    state.isLoading ? null : _saveProfile,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        const _SectionTitle(title: 'Change Password'),
                        const SizedBox(height: 14),
                        Form(
                          key: _passwordFormKey,
                          child: Column(
                            children: [
                              AppTextField(
                                label: 'New Password',
                                hintText: 'Enter new password',
                                prefixIcon: Icons.lock_outline,
                                controller: _passwordController,
                                obscureText: true,
                                textInputAction: TextInputAction.next,
                                validator: _requiredPassword,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: 'Confirm New Password',
                                hintText: 'Confirm new password',
                                prefixIcon: Icons.lock_reset,
                                controller: _confirmPasswordController,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                validator: _confirmPassword,
                                onSubmitted: (_) => _changePassword(),
                              ),
                              const SizedBox(height: 22),
                              OutlinedButton.icon(
                                onPressed:
                                    state.isLoading ? null : _changePassword,
                                icon: const Icon(Icons.password_rounded),
                                label: const Text('Update Password'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: LoginStyles.primaryColor,
                                  side: BorderSide(
                                    color: LoginStyles.primaryColor.withValues(
                                      alpha: 0.6,
                                    ),
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
                    ),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _pickProfileImage() async {
    XFile? pickedImage;
    try {
      pickedImage = await _imagePicker.pickImage(source: ImageSource.gallery);
    } on PlatformException catch (_) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Could not open the photo picker.');
      return;
    }

    final image = pickedImage;
    if (image == null) return;

    final contentType = _contentTypeForImage(image);
    if (!_allowedImageContentTypes.contains(contentType)) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Please choose a JPG or PNG image.');
      return;
    }

    final bytes = await image.readAsBytes();
    if (!mounted) return;
    if (bytes.length > _maxProfileImageBytes) {
      AppSnackBar.showError(context, 'Choose an image smaller than 5 MB.');
      return;
    }

    setState(() {
      _profileImageBytes = bytes;
      _profileImageName = image.name;
      _profileImageContentType = contentType;
    });
  }

  void _removeSelectedProfileImage() {
    setState(() {
      _profileImageBytes = null;
      _profileImageName = null;
      _profileImageContentType = null;
    });
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    await context.read<ProfileEditCubit>().saveProfile(
          fullName: _fullNameController.text,
          username: _usernameController.text,
          bio: _bioController.text,
          avatarBytes: _profileImageBytes,
          avatarFileName: _profileImageName,
          avatarContentType: _profileImageContentType,
        );

    if (!mounted) return;
    final state = context.read<ProfileEditCubit>().state;
    if (state.status == ProfileEditStatus.success) {
      AppSnackBar.showSuccess(context, 'Profile updated.');
      Navigator.pop(context, true);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    await context.read<ProfileEditCubit>().changePassword(
          _passwordController.text,
        );

    if (!mounted) return;
    final state = context.read<ProfileEditCubit>().state;
    if (state.status == ProfileEditStatus.success) {
      _passwordController.clear();
      _confirmPasswordController.clear();
      AppSnackBar.showSuccess(context, 'Password updated.');
    }
  }

  String? _required(String? value) {
    if ((value ?? '').trim().isEmpty) return 'This field is required';
    return null;
  }

  String? _requiredPassword(String? value) {
    final password = value ?? '';
    if (password.length < 6) return 'Use at least 6 characters';
    return null;
  }

  String? _confirmPassword(String? value) {
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  String _contentTypeForImage(XFile image) {
    final mimeType = image.mimeType;
    if (mimeType == 'image/jpg') return 'image/jpeg';
    if (mimeType != null && mimeType.isNotEmpty) return mimeType;

    final lowerName = image.name.toLowerCase();
    if (lowerName.endsWith('.png')) return 'image/png';
    return 'image/jpeg';
  }
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.imageBytes,
    required this.avatarUrl,
    required this.isLoading,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? imageBytes;
  final String? avatarUrl;
  final bool isLoading;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasSelectedImage = imageBytes != null;
    final hasRemoteImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 108,
              height: 108,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.loginPrimary,
                    AppColors.comingSoonPurple,
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(29),
                child: hasSelectedImage
                    ? Image.memory(imageBytes!, fit: BoxFit.cover)
                    : hasRemoteImage
                        ? Image.network(avatarUrl!, fit: BoxFit.cover)
                        : Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.cover,
                          ),
              ),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: IconButton(
                tooltip: 'Choose profile photo',
                onPressed: isLoading ? null : onPick,
                style: IconButton.styleFrom(
                  backgroundColor: LoginStyles.primaryColor,
                  foregroundColor: AppColors.white,
                  fixedSize: const Size(38, 38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.photo_camera_outlined, size: 19),
              ),
            ),
            if (hasSelectedImage)
              Positioned(
                left: -4,
                bottom: -4,
                child: IconButton(
                  tooltip: 'Remove selected photo',
                  onPressed: isLoading ? null : onRemove,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textMuted,
                    fixedSize: const Size(38, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.close, size: 19),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: isLoading ? null : onPick,
          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
          label: const Text('Choose JPG or PNG'),
          style: TextButton.styleFrom(
            foregroundColor: LoginStyles.primaryColor,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
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
