import 'dart:typed_data';

import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/login/presentation/widgets/login_styles.dart';
import 'package:flutter/material.dart';

class EditableAvatar extends StatelessWidget {
  const EditableAvatar({
    super.key,
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
