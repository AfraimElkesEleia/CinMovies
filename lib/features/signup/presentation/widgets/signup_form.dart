import 'dart:typed_data';

import 'package:cinmovies_app/core/widgets/app_text_field.dart';
import 'package:cinmovies_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:cinmovies_app/features/login/presentation/widgets/login_primary_button.dart';
import 'package:cinmovies_app/features/signup/presentation/widgets/signup_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignupForm extends StatelessWidget {
  const SignupForm({
    super.key,
    required this.formKey,
    required this.fullNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.profileImageBytes,
    required this.onPickProfileImage,
    required this.onRemoveProfileImage,
    required this.onSubmit,
    required this.requiredValidator,
    required this.emailValidator,
    required this.passwordValidator,
    required this.confirmPasswordValidator,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final Uint8List? profileImageBytes;
  final VoidCallback? onPickProfileImage;
  final VoidCallback? onRemoveProfileImage;
  final VoidCallback onSubmit;
  final FormFieldValidator<String> requiredValidator;
  final FormFieldValidator<String> emailValidator;
  final FormFieldValidator<String> passwordValidator;
  final FormFieldValidator<String> confirmPasswordValidator;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthCubit>().state;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SignupProfileImagePicker(
              imageBytes: profileImageBytes,
              onTap: state.isLoading ? null : onPickProfileImage,
              onRemove: state.isLoading ? null : onRemoveProfileImage,
            ),
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Full Name',
            hintText: 'John Doe',
            prefixIcon: Icons.person,
            controller: fullNameController,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            validator: requiredValidator,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Email',
            hintText: 'your@email.com',
            prefixIcon: Icons.email,
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: emailValidator,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Password',
            hintText: 'Enter your password',
            prefixIcon: Icons.lock,
            controller: passwordController,
            obscureText: true,
            textInputAction: TextInputAction.next,
            validator: passwordValidator,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Confirm Password',
            hintText: 'Confirm your password',
            prefixIcon: Icons.lock,
            controller: confirmPasswordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: confirmPasswordValidator,
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 18),
          SignupTermsAgreement(
            agreed: state.termsAccepted,
            onChanged: context.read<AuthCubit>().setTermsAccepted,
          ),
          const SizedBox(height: 20),
          LoginPrimaryButton(
            text: state.isLoading ? 'Creating...' : 'Create Account',
            onPressed: state.isLoading ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}
