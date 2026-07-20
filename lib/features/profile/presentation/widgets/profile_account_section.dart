import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ProfileAccountSection extends StatelessWidget {
  const ProfileAccountSection({
    super.key,
    required this.onMyReviewsPressed,
    required this.onFavoriteGenresPressed,
    required this.onSupportHelpPressed,
    required this.onLogoutPressed,
  });

  final VoidCallback onMyReviewsPressed;
  final VoidCallback onFavoriteGenresPressed;
  final VoidCallback onSupportHelpPressed;
  final VoidCallback onLogoutPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.surfaceBorder),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _AccountActionTile(
                  icon: Icons.rate_review_outlined,
                  title: 'My Reviews',
                  subtitle: 'Ratings and notes you shared',
                  onPressed: onMyReviewsPressed,
                ),
                const _AccountDivider(),
                _AccountActionTile(
                  icon: Icons.category_outlined,
                  title: 'Favorite Genres',
                  subtitle: 'Your preferred movie categories',
                  onPressed: onFavoriteGenresPressed,
                ),
                const _AccountDivider(),
                _AccountActionTile(
                  icon: Icons.support_agent_rounded,
                  title: 'Support & Help',
                  subtitle: 'Get help with your account',
                  onPressed: onSupportHelpPressed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _LogoutButton(onPressed: onLogoutPressed),
        ],
      ),
    );
  }
}

class _AccountActionTile extends StatelessWidget {
  const _AccountActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.loginPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: AppColors.loginPrimary, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.iconMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.iconMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountDivider extends StatelessWidget {
  const _AccountDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 68),
      child: Divider(height: 1, thickness: 1, color: AppColors.surfaceBorder),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout_rounded, size: 19),
        label: const Text('Logout'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.loginPrimary,
          side: BorderSide(
            color: AppColors.loginPrimary.withValues(alpha: 0.55),
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
    );
  }
}
