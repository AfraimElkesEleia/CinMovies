import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/widgets/app_snack_bar.dart';
import 'package:cinmovies_app/core/widgets/auth_screen_layout.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:cinmovies_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:cinmovies_app/features/onboarding_screen/data/preference_repository.dart';
import 'package:cinmovies_app/features/signup/presentation/widgets/signup_form.dart';
import 'package:cinmovies_app/features/signup/presentation/widgets/signup_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AuthCubit(sl<AuthRepository>(), sl<PreferenceRepository>()),
      child: const _SignupView(),
    );
  }
}

class _SignupView extends StatefulWidget {
  const _SignupView();

  @override
  State<_SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<_SignupView> {
  static const _allowedImageContentTypes = {'image/jpeg', 'image/png'};
  static const _maxProfileImageBytes = 5 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _imagePicker = ImagePicker();
  Uint8List? _profileImageBytes;
  String? _profileImageName;
  String? _profileImageContentType;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == AuthSubmissionStatus.success) {
          context.pushNamedAndRemoveUntil(Routes.preferenceOnboarding);
        }

        if (state.status == AuthSubmissionStatus.failure &&
            state.errorMessage != null) {
          AppSnackBar.showError(context, state.errorMessage!);
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return AuthScreenLayout(
            header: const SignupHeader(),
            children: [
              SignupForm(
                formKey: _formKey,
                fullNameController: _fullNameController,
                emailController: _emailController,
                passwordController: _passwordController,
                confirmPasswordController: _confirmPasswordController,
                profileImageBytes: _profileImageBytes,
                onPickProfileImage: _pickProfileImage,
                onRemoveProfileImage: _removeProfileImage,
                onSubmit: () => _createAccount(context),
                requiredValidator: _required,
                emailValidator: _requiredEmail,
                passwordValidator: _requiredPassword,
                confirmPasswordValidator: _confirmPassword,
              ),
              const SizedBox(height: 16),
              const SignupSocialActions(),
              const SizedBox(height: 32),
              LoginPrompt(
                onLoginPressed: () =>
                    context.pushNamedAndRemoveUntil(Routes.login),
              ),
            ],
          );
        },
      ),
    );
  }

  String? _required(String? value) {
    if ((value ?? '').trim().isEmpty) return 'This field is required';
    return null;
  }

  String? _requiredEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!email.contains('@')) return 'Enter a valid email';
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

  void _createAccount(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthCubit>().signup(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      avatarBytes: _profileImageBytes,
      avatarFileName: _profileImageName,
      avatarContentType: _profileImageContentType,
    );
  }

  Future<void> _pickProfileImage() async {
    XFile? pickedImage;
    try {
      pickedImage = await _imagePicker.pickImage(source: ImageSource.gallery);
    } on PlatformException catch (_) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        'Could not open the photo picker. Rebuild the app and try again.',
      );
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

  void _removeProfileImage() {
    setState(() {
      _profileImageBytes = null;
      _profileImageName = null;
      _profileImageContentType = null;
    });
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
