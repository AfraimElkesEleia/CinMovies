import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/core/widgets/app_snack_bar.dart';
import 'package:cinmovies_app/core/widgets/app_text_field.dart';
import 'package:cinmovies_app/core/widgets/auth_screen_layout.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:cinmovies_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:cinmovies_app/features/login/presentation/widgets/auth_divider.dart';
import 'package:cinmovies_app/features/login/presentation/widgets/login_primary_button.dart';
import 'package:cinmovies_app/features/login/presentation/widgets/login_styles.dart';
import 'package:cinmovies_app/features/login/presentation/widgets/login_with_button.dart';
import 'package:cinmovies_app/features/onboarding_screen/data/preference_repository.dart';
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
            header: const _SignupHeader(),
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: _ProfileImagePicker(
                        imageBytes: _profileImageBytes,
                        onTap: state.isLoading ? null : _pickProfileImage,
                        onRemove: state.isLoading ? null : _removeProfileImage,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      label: 'Full Name',
                      hintText: 'John Doe',
                      prefixIcon: Icons.person,
                      controller: _fullNameController,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      validator: _required,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Email',
                      hintText: 'your@email.com',
                      prefixIcon: Icons.email,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _requiredEmail,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Icons.lock,
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      validator: _requiredPassword,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Confirm Password',
                      hintText: 'Confirm your password',
                      prefixIcon: Icons.lock,
                      controller: _confirmPasswordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: _confirmPassword,
                      onSubmitted: (_) => _createAccount(context),
                    ),
                    const SizedBox(height: 18),
                    _TermsAgreement(
                      agreed: state.termsAccepted,
                      onChanged: context.read<AuthCubit>().setTermsAccepted,
                    ),
                    const SizedBox(height: 20),
                    LoginPrimaryButton(
                      text: state.isLoading ? 'Creating...' : 'Create Account',
                      onPressed: state.isLoading
                          ? null
                          : () => _createAccount(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const AuthDivider(text: 'or continue with'),
              const SizedBox(height: 16),
              Row(
                children: [
                  LoginWithButton(
                    buttonText: 'Google',
                    buttonIcon: 'assets/images/google_icon.png',
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  LoginWithButton(
                    buttonText: 'Facebook',
                    buttonIcon: 'assets/images/facebook_icon.png',
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _LoginPrompt(
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

class _ProfileImagePicker extends StatelessWidget {
  const _ProfileImagePicker({
    required this.imageBytes,
    required this.onTap,
    required this.onRemove,
  });

  final Uint8List? imageBytes;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 96,
                height: 96,
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
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(27),
                  child: hasImage
                      ? Image.memory(imageBytes!, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.surface,
                          child: const Icon(
                            Icons.person_add_alt_1,
                            color: AppColors.textMuted,
                            size: 34,
                          ),
                        ),
                ),
              ),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: IconButton(
                tooltip: hasImage
                    ? 'Change profile image'
                    : 'Add profile image',
                onPressed: onTap,
                style: IconButton.styleFrom(
                  backgroundColor: LoginStyles.primaryColor,
                  foregroundColor: AppColors.white,
                  fixedSize: const Size(36, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
              ),
            ),
            if (hasImage)
              Positioned(
                left: -4,
                bottom: -4,
                child: IconButton(
                  tooltip: 'Remove profile image',
                  onPressed: onRemove,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textMuted,
                    fixedSize: const Size(36, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: onTap,
          icon: Icon(
            hasImage ? Icons.swap_horiz : Icons.add_photo_alternate_outlined,
            size: 18,
          ),
          label: Text(hasImage ? 'Change photo' : 'Add profile photo'),
          style: TextButton.styleFrom(
            foregroundColor: LoginStyles.primaryColor,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _SignupHeader extends StatelessWidget {
  const _SignupHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Start discovering your next favorite movie',
          style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TermsAgreement extends StatelessWidget {
  const _TermsAgreement({required this.agreed, required this.onChanged});

  final bool agreed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!agreed),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: agreed,
            activeColor: LoginStyles.primaryColor,
            side: const BorderSide(color: LoginStyles.borderColor),
            onChanged: (checked) => onChanged(checked ?? false),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                  children: const [
                    TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(color: LoginStyles.primaryColor),
                    ),
                    TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(color: LoginStyles.primaryColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.onLoginPressed});

  final VoidCallback onLoginPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onLoginPressed,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Already have an account? ',
              style: TextStyle(
                color: LoginStyles.textColor.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
            const TextSpan(
              text: 'Login',
              style: TextStyle(
                color: LoginStyles.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
