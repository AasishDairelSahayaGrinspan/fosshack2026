import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'home_screen.dart';
import 'placeholder_screen.dart';

/// Main navigation shell with bottom tab bar.
/// 5 tabs: Home, Journal, Community, Music, Profile
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    PlaceholderScreen(
      title: 'Journal',
      icon: Icons.edit_note_rounded,
      message: 'Your thoughts, safely kept.',
    ),
    PlaceholderScreen(
      title: 'Community',
      icon: Icons.people_outline_rounded,
      message: 'A space to connect.',
    ),
    PlaceholderScreen(
      title: 'Music',
      icon: Icons.music_note_outlined,
      message: 'Sounds that heal.',
    ),
    PlaceholderScreen(
      title: 'Profile',
      icon: Icons.person_outline_rounded,
      message: 'Your safe space.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: AppTheme.fadeInDuration,
        switchInCurve: AppTheme.defaultCurve,
        switchOutCurve: AppTheme.defaultCurve,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _buildNavItem(
                1,
                Icons.edit_note_outlined,
                Icons.edit_note_rounded,
                'Journal',
              ),
              _buildNavItem(
                2,
                Icons.people_outline_rounded,
                Icons.people_rounded,
                'Community',
              ),
              _buildNavItem(
                3,
                Icons.music_note_outlined,
                Icons.music_note_rounded,
                'Music',
              ),
              _buildNavItem(
                4,
                Icons.person_outline_rounded,
                Icons.person_rounded,
                'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppTheme.fadeInDuration,
        curve: AppTheme.defaultCurve,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.softIndigo.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? filledIcon : outlinedIcon,
                key: ValueKey<bool>(isSelected),
                color: isSelected
                    ? AppColors.softIndigo
                    : AppColors.textTertiary,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style:
                  AppTypography.caption(
                    color: isSelected
                        ? AppColors.softIndigo
                        : AppColors.textTertiary,
                  ).copyWith(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
