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
import '../models/avatar_config.dart';
import '../services/user_preferences_service.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/app_navigation_service.dart';
import '../widgets/avatar_renderer.dart';
import 'breathing_screen.dart';
import 'sleep_tracker_screen.dart';
import 'journal_screen.dart';
import 'timer_screen.dart';

/// Unravel Home Screen - the emotional dashboard.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _recoveryScore = 100.0;
  List<double> _moodData = List<double>.filled(7, 0.5);
  int _streakDays = 0;

  String? _needMessage;
  bool _highlightTimer = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final db = DatabaseService();
    final scoreFuture = db.getLatestRecoveryScore(user.$id).catchError((_) => 100.0);
    final moodFuture = db.getMoodEntries(user.$id, days: 7).catchError((_) => LocalRowList(rows: <LocalRow>[]));
    final streakFuture = db.getOrCreateStreak(user.$id).catchError((_) => LocalRow($id: user.$id, data: <String, dynamic>{'currentStreak': 0}));

    final results = await Future.wait<dynamic>([scoreFuture, moodFuture, streakFuture]);
    if (!mounted) return;

    final score = (results[0] as num?)?.toDouble() ?? 100.0;
    final moodResult = results[1] as LocalRowList;
    final streakDoc = results[2] as LocalRow;

    setState(() {
      _recoveryScore = (score / 100.0).clamp(0.0, 1.0);
      if (moodResult.rows.isNotEmpty) {
        _moodData = moodResult.rows
            .map<double>((d) => ((d.data['mood'] as num?)?.toDouble() ?? 0.5))
            .toList();
      }
      _streakDays = (streakDoc.data['currentStreak'] as num?)?.toInt() ?? 0;
    });
  }

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
              position: Tween<Offset>(
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

  void _handleNeedSelection(String need) {
    switch (need) {
      case 'Focus':
        setState(() {
          _highlightTimer = true;
          _needMessage = 'Use Timer to gain focus, or open Music for lofi focus tracks.';
        });
        AppNavigationService().highlightTab(AppTabTarget.music);
        AppNavigationService().setMusicRecommendation('Focus mood: Try Focus Mode / Instrumental calm.');
        Future.delayed(const Duration(seconds: 3), () {
          if (!mounted) return;
          setState(() => _highlightTimer = false);
          AppNavigationService().clearHighlight();
        });
        break;
      case 'Calm':
        setState(() {
          _needMessage = 'Calm mode: open Music and play gentle calming songs.';
          _highlightTimer = false;
        });
        AppNavigationService().setMusicRecommendation('Calm mood: Try Soft Tamil Evenings or Deep Calm.');
        AppNavigationService().requestTab(AppTabTarget.music);
        break;
      case 'Release thoughts':
        setState(() {
          _needMessage = 'Opening Journal so you can release your thoughts.';
          _highlightTimer = false;
        });
        _navigate(context, const JournalScreen());
        break;
      case 'Rest':
        setState(() {
          _needMessage = 'Rest mode: listen to mild, slow tracks in Music.';
          _highlightTimer = false;
        });
        AppNavigationService().setMusicRecommendation('Rest mood: Try Sleep Mode and soft ambient tracks.');
        AppNavigationService().requestTab(AppTabTarget.music);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      colors: AppColors.bgGradient(context),
      secondaryColors: AppColors.bgGradientAlt(context),
      child: SafeArea(
        child: DoodleRefresh(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    RepaintBoundary(child: _buildGreetingHeader(context)),
                    const SizedBox(height: 32),
                    RepaintBoundary(
                      child: MoodSelector(
                        onMoodSaved: (_) => _loadData(),
                      ),
                    ),
                    const SizedBox(height: 28),
                    RepaintBoundary(
                      child: RecoveryScoreCard(score: _recoveryScore),
                    ),
                    const SizedBox(height: 28),
                    RepaintBoundary(
                      child: DailyCheckin(
                        onNeedSelected: _handleNeedSelection,
                      ),
                    ),
                    if (_needMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.softIndigo.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          border: Border.all(
                            color: AppColors.softIndigo.withValues(alpha: 0.35),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.softIndigo.withValues(alpha: 0.22),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.softIndigo),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _needMessage!,
                                style: AppTypography.caption(color: AppColors.primary(context)),
                              ),
                            ),
                            TextButton(
                              onPressed: () => AppNavigationService().requestTab(AppTabTarget.music),
                              child: Text(
                                'Music',
                                style: AppTypography.caption(color: AppColors.softIndigo)
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    Text(
                      'Explore',
                      style: AppTypography.sectionHeadingC(context),
                    ),
                    const SizedBox(height: 14),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  delegate: SliverChildListDelegate([
                    QuickActionButton(
                      icon: Icons.air_rounded,
                      label: 'Breathing',
                      iconColor: AppColors.softIndigo,
                      onTap: () => _navigate(context, const BreathingScreen()),
                    ),
                    QuickActionButton(
                      icon: Icons.timer_outlined,
                      label: 'Timer',
                      iconColor: AppColors.sageGreen,
                      highlight: _highlightTimer,
                      onTap: () => _navigate(context, const TimerScreen()),
                    ),
                    QuickActionButton(
                      icon: Icons.nightlight_outlined,
                      label: 'Sleep Tracker',
                      iconColor: AppColors.warmCoral,
                      onTap: () => _navigate(context, const SleepTrackerScreen()),
                    ),
                    QuickActionButton(
                      icon: Icons.edit_note_rounded,
                      label: 'Journal',
                      iconColor: AppColors.orangeE2814d,
                      onTap: () => _navigate(context, const JournalScreen()),
                    ),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    RepaintBoundary(child: MoodChart(moodData: _moodData)),
                    const SizedBox(height: 24),
                    RepaintBoundary(
                      child: CommunityActivityCard(
                        onTap: () => AppNavigationService().requestTab(AppTabTarget.community),
                      ),
                    ),
                    const SizedBox(height: 24),
                    RepaintBoundary(
                      child: StreakIndicator(streakDays: _streakDays),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarWidget(double size) {
    final prefs = UserPreferencesService();
    if (prefs.avatarData != null && prefs.avatarData!.isNotEmpty) {
      return AvatarRenderer(
        config: AvatarConfig.fromJsonString(prefs.avatarData!),
        size: size,
      );
    }
    // Fallback to DiceBear
    return Image.network(
      prefs.getAvatarUrl(),
      fit: BoxFit.cover,
      cacheWidth: (size * 2).toInt(),
      cacheHeight: (size * 2).toInt(),
      errorBuilder: (context, error, stackTrace) {
        return Container(
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
          ),
          child: Center(
            child: Icon(
              Icons.person_outline_rounded,
              color: AppColors.secondary(context),
              size: size * 0.45,
            ),
          ),
        );
      },
    );
  }

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
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.softIndigo.withValues(alpha: 0.2),
              width: 1.5,
            ),
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
          child: ClipOval(
            child: _buildAvatarWidget(54),
          ),
        ),
      ],
    );
  }
}
