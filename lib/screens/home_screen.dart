import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/gradient_background.dart';
import '../widgets/mood_selector.dart';
import '../widgets/recovery_score_card.dart';
import '../widgets/daily_checkin.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/streak_indicator.dart';
import '../widgets/mood_chart.dart';
import '../widgets/community_activity_card.dart';
import '../widgets/doodle_refresh.dart';
import '../services/user_preferences_service.dart';
import 'breathing_screen.dart';
import 'sleep_tracker_screen.dart';
import 'journal_screen.dart';
import 'timer_screen.dart';

/// Unravel Home Screen — the emotional dashboard.
/// Layout: Greeting → Mood Selector → Recovery Score → Daily Check-in
///       → Quick Actions → Charts → Streak
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final name = UserPreferencesService().displayName;
    final prefix = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    return '$prefix, $name.';
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, a1, a2) => screen,
        transitionsBuilder: (context2, animation, a3, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: AppTheme.gentleCurve,
            ),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: AppTheme.gentleCurve,
                    ),
                  ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      colors: AppColors.bgGradient(context),
      secondaryColors: AppColors.bgGradientAlt(context),
      child: SafeArea(
        child: DoodleRefresh(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ─── Greeting Header with Avatar ───
                RepaintBoundary(child: _buildGreetingHeader(context)),

                const SizedBox(height: 32),

                // ─── Mood Selector ───
                RepaintBoundary(child: const MoodSelector()),

                const SizedBox(height: 28),

                // ─── Recovery Score with Quote ───
                RepaintBoundary(child: const RecoveryScoreCard(score: 0.78)),

                const SizedBox(height: 28),

                // ─── Daily Check-in ───
                RepaintBoundary(child: const DailyCheckin()),

                const SizedBox(height: 28),

                // ─── Quick Actions (links to Phase 4 modules) ───
                Text('Explore', style: AppTypography.sectionHeadingC(context)),
                const SizedBox(height: 14),
                RepaintBoundary(
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      QuickActionButton(
                        icon: Icons.air_rounded,
                        label: 'Breathing',
                        iconColor: AppColors.softIndigo,
                        onTap: () =>
                            _navigate(context, const BreathingScreen()),
                      ),
                      QuickActionButton(
                        icon: Icons.timer_outlined,
                        label: 'Timer',
                        iconColor: AppColors.sageGreen,
                        onTap: () => _navigate(context, const TimerScreen()),
                      ),
                      QuickActionButton(
                        icon: Icons.nightlight_outlined,
                        label: 'Sleep Tracker',
                        iconColor: AppColors.warmCoral,
                        onTap: () =>
                            _navigate(context, const SleepTrackerScreen()),
                      ),
                      QuickActionButton(
                        icon: Icons.edit_note_rounded,
                        label: 'Journal',
                        iconColor: const Color(0xFFB8A9C9),
                        onTap: () => _navigate(context, const JournalScreen()),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ─── Weekly Mood Chart ───
                RepaintBoundary(
                  child: const MoodChart(
                    moodData: [0.4, 0.55, 0.6, 0.45, 0.7, 0.8, 0.65],
                  ),
                ),

                const SizedBox(height: 24),

                // ─── Community Activity Card ───
                RepaintBoundary(
                  child: CommunityActivityCard(
                    onTap: () {
                      // Navigate to community tab (index 2) via MainShell
                      // For now this is a gentle invite
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // ─── Streak Indicator ───
                RepaintBoundary(child: const StreakIndicator(streakDays: 7)),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Greeting header with time-based text and glowing avatar
  Widget _buildGreetingHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_getGreeting(), style: AppTypography.heroHeadingC(context)),
              const SizedBox(height: 6),
              Text(
                'How is your mind today?',
                style: AppTypography.subtitleC(context),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Avatar with soft glow
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.softIndigo.withValues(alpha: 0.25),
                AppColors.paleLilac.withValues(alpha: 0.5),
              ],
            ),
            border: Border.all(color: AppColors.frostedGlassBorder, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.softIndigo.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: AppColors.paleLilac.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.person_outline_rounded,
              color: AppColors.secondary(context),
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}
