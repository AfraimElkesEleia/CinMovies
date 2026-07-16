import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum AppNavTab {
  home(
    label: 'Home',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
  ),
  browse(
    label: 'Browse',
    icon: Icons.grid_view_outlined,
    activeIcon: Icons.grid_view_rounded,
  ),
  ai(
    label: 'AI',
    icon: Icons.auto_awesome_outlined,
    activeIcon: Icons.auto_awesome_rounded,
  ),
  library(
    label: 'Library',
    icon: Icons.video_library_outlined,
    activeIcon: Icons.video_library_rounded,
  ),
  profile(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
  );

  const AppNavTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final AppNavTab currentTab;
  final ValueChanged<AppNavTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / AppNavTab.values.length;
        final aiButtonSize = (itemWidth * 0.52).clamp(40.0, 48.0);

        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.scaffoldBackground,
            border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 68,
              child: Row(
                children: AppNavTab.values.map((tab) {
                  return Expanded(
                    child: _AppBottomNavigationItem(
                      tab: tab,
                      isSelected: tab == currentTab,
                      aiButtonSize: aiButtonSize,
                      onTap: () => onTabSelected(tab),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AppBottomNavigationItem extends StatelessWidget {
  const _AppBottomNavigationItem({
    required this.tab,
    required this.isSelected,
    required this.aiButtonSize,
    required this.onTap,
  });

  final AppNavTab tab;
  final bool isSelected;
  final double aiButtonSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAiTab = tab == AppNavTab.ai;
    final itemColor = isSelected ? AppColors.loginPrimary : AppColors.iconMuted;

    return InkWell(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          if (!isAiTab)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 24 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.loginPrimary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(top: isAiTab ? 0 : 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAiTab)
                  _AiNavigationIcon(isSelected: isSelected, size: aiButtonSize)
                else
                  Icon(
                    isSelected ? tab.activeIcon : tab.icon,
                    size: 24,
                    color: itemColor,
                  ),
                SizedBox(height: isAiTab ? 2 : 4),
                Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: itemColor,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiNavigationIcon extends StatelessWidget {
  const _AiNavigationIcon({required this.isSelected, required this.size});

  final bool isSelected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -size * 0.35),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? const [AppColors.loginPrimary, AppColors.comingSoonPurple]
                : const [AppColors.surfaceBorder, AppColors.surface],
          ),
          borderRadius: BorderRadius.circular(size * 0.34),
          border: isSelected
              ? null
              : Border.all(color: AppColors.surfaceBorder),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.loginPrimary.withValues(alpha: 0.38),
                    blurRadius: size * 0.45,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Icon(
          isSelected ? Icons.auto_awesome_rounded : Icons.auto_awesome_outlined,
          color: AppColors.white,
          size: size * 0.45,
        ),
      ),
    );
  }
}
