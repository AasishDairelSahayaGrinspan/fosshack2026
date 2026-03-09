import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../services/community_service.dart';
import 'home_screen.dart';
import 'journal_screen.dart';
import 'community_feed_screen.dart';
import 'music_screen.dart';
import 'profile_screen.dart';

/// Main navigation shell with bottom tab bar.
/// Tabs adapt based on community preference.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  bool get _showCommunity => CommunityService().communityPreference != 'no';

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const JournalScreen();
      case 2:
        if (_showCommunity) return const CommunityFeedScreen();
        return const MusicScreen();
      case 3:
        if (_showCommunity) return const MusicScreen();
        return const ProfileScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor(context),
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
              _buildNavItem(
                context,
                0,
                Icons.home_outlined,
                Icons.home_rounded,
                'Home',
              ),
              _buildNavItem(
                context,
                1,
                Icons.edit_note_outlined,
                Icons.edit_note_rounded,
                'Journal',
              ),
              if (_showCommunity)
                _buildNavItem(
                  context,
                  2,
                  Icons.people_outline_rounded,
                  Icons.people_rounded,
                  'Community',
                ),
              _buildNavItem(
                context,
                _showCommunity ? 3 : 2,
                Icons.music_note_outlined,
                Icons.music_note_rounded,
                'Music',
              ),
              _buildNavItem(
                context,
                _showCommunity ? 4 : 3,
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
    BuildContext context,
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
                    : AppColors.tertiary(context),
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
                        : AppColors.tertiary(context),
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
