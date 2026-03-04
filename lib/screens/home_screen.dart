import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/gradient_background.dart';
import '../widgets/mood_selector.dart';
import '../widgets/recovery_score_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/streak_indicator.dart';
import '../widgets/mood_chart.dart';

/// MindHaven Home Screen — calm, breathable dashboard.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      colors: const [AppColors.cream, AppColors.lightBlush],
      secondaryColors: const [AppColors.paleLilac, AppColors.cream],
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ─── Greeting Header ───
              _buildGreetingHeader()
                  .animate()
                  .fadeIn(
                    duration: const Duration(milliseconds: 600),
                    curve: AppTheme.gentleCurve,
                  )
                  .slideY(
                    begin: 0.1,
                    end: 0,
                    duration: const Duration(milliseconds: 600),
                    curve: AppTheme.gentleCurve,
                  ),

              const SizedBox(height: 28),

              // ─── Mood Selector ───
              const MoodSelector()
                  .animate(delay: const Duration(milliseconds: 150))
                  .fadeIn(
                    duration: const Duration(milliseconds: 500),
                    curve: AppTheme.gentleCurve,
                  ),

              const SizedBox(height: 24),

              // ─── Recovery Score ───
              const RecoveryScoreCard(score: 0.78)
                  .animate(delay: const Duration(milliseconds: 250))
                  .fadeIn(
                    duration: const Duration(milliseconds: 500),
                    curve: AppTheme.gentleCurve,
                  )
                  .slideY(
                    begin: 0.06,
                    end: 0,
                    duration: const Duration(milliseconds: 500),
                    curve: AppTheme.gentleCurve,
                  ),

              const SizedBox(height: 24),

              // ─── Quick Actions ───
              Text('Quick Actions', style: AppTypography.sectionHeading())
                  .animate(delay: const Duration(milliseconds: 350))
                  .fadeIn(duration: const Duration(milliseconds: 400)),
              const SizedBox(height: 14),
              GridView.count(
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
                        onTap: () {},
                      ),
                      QuickActionButton(
                        icon: Icons.timer_outlined,
                        label: 'Start Timer',
                        iconColor: AppColors.sageGreen,
                        onTap: () {},
                      ),
                      QuickActionButton(
                        icon: Icons.nightlight_outlined,
                        label: 'Sleep Tracker',
                        iconColor: AppColors.warmCoral,
                        onTap: () {},
                      ),
                      QuickActionButton(
                        icon: Icons.edit_note_rounded,
                        label: 'Daily Journal',
                        iconColor: const Color(0xFFB8A9C9),
                        onTap: () {},
                      ),
                    ],
                  )
                  .animate(delay: const Duration(milliseconds: 400))
                  .fadeIn(
                    duration: const Duration(milliseconds: 500),
                    curve: AppTheme.gentleCurve,
                  ),

              const SizedBox(height: 24),

              // ─── Streak Indicator ───
              const StreakIndicator(streakDays: 5)
                  .animate(delay: const Duration(milliseconds: 500))
                  .fadeIn(
                    duration: const Duration(milliseconds: 500),
                    curve: AppTheme.gentleCurve,
                  )
                  .slideY(
                    begin: 0.06,
                    end: 0,
                    duration: const Duration(milliseconds: 500),
                    curve: AppTheme.gentleCurve,
                  ),

              const SizedBox(height: 24),

              // ─── Weekly Mood Chart ───
              const MoodChart(moodData: [0.4, 0.55, 0.6, 0.45, 0.7, 0.8, 0.65])
                  .animate(delay: const Duration(milliseconds: 600))
                  .fadeIn(
                    duration: const Duration(milliseconds: 500),
                    curve: AppTheme.gentleCurve,
                  )
                  .slideY(
                    begin: 0.06,
                    end: 0,
                    duration: const Duration(milliseconds: 500),
                    curve: AppTheme.gentleCurve,
                  ),

              // Bottom padding to clear nav bar
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Greeting header with avatar
  Widget _buildGreetingHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hey buddy 🌿', style: AppTypography.heroHeading()),
            const SizedBox(height: 4),
            Text('Take a deep breath today.', style: AppTypography.subtitle()),
          ],
        ),
        // Avatar circle
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.softIndigo.withValues(alpha: 0.3),
                AppColors.paleLilac.withValues(alpha: 0.6),
              ],
            ),
            border: Border.all(color: AppColors.frostedGlassBorder, width: 2),
            boxShadow: AppColors.subtleShadow,
          ),
          child: const Center(
            child: Icon(
              Icons.person_outline_rounded,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}
