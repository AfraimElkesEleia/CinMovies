import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/core/widgets/app_snack_bar.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:cinmovies_app/features/login/presentation/widgets/login_styles.dart';
import 'package:cinmovies_app/features/profile/data/profile_repository.dart';
import 'package:cinmovies_app/features/profile/presentation/cubit/profile_edit_cubit.dart';
import 'package:cinmovies_app/features/profile/presentation/widgets/edit_profile_forms.dart';
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
                    child: EditProfileForms(
                      state: state,
                      profileFormKey: _profileFormKey,
                      passwordFormKey: _passwordFormKey,
                      fullNameController: _fullNameController,
                      usernameController: _usernameController,
                      bioController: _bioController,
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      profileImageBytes: _profileImageBytes,
                      onPickProfileImage: _pickProfileImage,
                      onRemoveProfileImage: _removeSelectedProfileImage,
                      onSaveProfile: _saveProfile,
                      onChangePassword: _changePassword,
                      requiredValidator: _required,
                      passwordValidator: _requiredPassword,
                      confirmPasswordValidator: _confirmPassword,
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
