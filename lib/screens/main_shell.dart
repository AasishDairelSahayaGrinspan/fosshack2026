import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../services/community_service.dart';
import '../services/app_navigation_service.dart';
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
  int? _highlightIndex;
  DateTime? _lastBackPress;
  late final bool _showCommunity;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _showCommunity = CommunityService().communityPreference != 'no';
    _screens = <Widget>[
      const HomeScreen(),
      const JournalScreen(),
      if (_showCommunity) const CommunityFeedScreen(),
      const MusicScreen(),
      const ProfileScreen(),
    ];
    AppNavigationService().tabRequest.addListener(_onTabRequest);
    AppNavigationService().tabHighlight.addListener(_onTabHighlight);
  }

  @override
  void dispose() {
    AppNavigationService().tabRequest.removeListener(_onTabRequest);
    AppNavigationService().tabHighlight.removeListener(_onTabHighlight);
    super.dispose();
  }

  int _tabToIndex(AppTabTarget target) {
    switch (target) {
      case AppTabTarget.home:
        return 0;
      case AppTabTarget.journal:
        return 1;
      case AppTabTarget.community:
        return _showCommunity ? 2 : 0;
      case AppTabTarget.music:
        return _showCommunity ? 3 : 2;
      case AppTabTarget.profile:
        return _showCommunity ? 4 : 3;
    }
  }

  void _onTabRequest() {
    final request = AppNavigationService().tabRequest.value;
    if (request == null) return;
    setState(() => _currentIndex = _tabToIndex(request));
    AppNavigationService().clearTabRequest();
  }

  void _onTabHighlight() {
    final request = AppNavigationService().tabHighlight.value;
    if (request == null) return;
    final idx = _tabToIndex(request);
    setState(() => _highlightIndex = idx);
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _highlightIndex = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final safeIndex = _currentIndex.clamp(0, _screens.length - 1);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }
        final now = DateTime.now();
        if (_lastBackPress != null &&
            now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          Navigator.of(context).pop();
          return;
        }
        _lastBackPress = now;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Scaffold(
        body: IndexedStack(
          index: safeIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildBottomNavBar(context),
      ),
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
    final isHighlighted = _highlightIndex == index;

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
          border: isHighlighted
              ? Border.all(
                  color: AppColors.amberFdb903,
                  width: 1.2,
                )
              : null,
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: AppColors.amberFdb903.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 1.5,
                  ),
                ]
              : null,
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
