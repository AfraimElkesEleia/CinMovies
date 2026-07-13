import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum AppNavTab {
  home(
    label: 'Home',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
  ),
  search(
    label: 'Search',
    icon: Icons.search_rounded,
    activeIcon: Icons.search_rounded,
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
                  onTap: () => onTabSelected(tab),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _AppBottomNavigationItem extends StatelessWidget {
  const _AppBottomNavigationItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final AppNavTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final itemColor = isSelected ? AppColors.loginPrimary : AppColors.iconMuted;

    return InkWell(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
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
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? tab.activeIcon : tab.icon,
                  size: 24,
                  color: itemColor,
                ),
                const SizedBox(height: 4),
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
