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
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/app_navigation_service.dart';
import '../services/notification_service.dart';
import '../models/avatar_config.dart';
import '../widgets/custom_avatar.dart';
import '../services/activity_service.dart';
import 'breathing_screen.dart';
import 'sleep_tracker_screen.dart';
import 'journal_screen.dart';
import 'timer_screen.dart';
import 'insights_screen.dart';

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
  bool _activityPermissionDismissed = false;

  List<_Suggestion> _needSuggestions = [];
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

    final rawScore = (results[0] as num?)?.toDouble() ?? 100.0;
    final moodResult = results[1] as LocalRowList;
    final streakDoc = results[2] as LocalRow;

    setState(() {
      // rawScore is 0–100 from database; convert to 0.0–1.0 for the widget.
      _recoveryScore = (rawScore / 100.0).clamp(0.0, 1.0);
      if (moodResult.rows.isNotEmpty) {
        _moodData = moodResult.rows
            .map<double>((d) => ((d.data['mood'] as num?)?.toDouble() ?? 0.5))
            .toList();
      }
      _streakDays = (streakDoc.data['currentStreak'] as num?)?.toInt() ?? 0;
      // Schedule streak encouragement if streak >= 3
      if (_streakDays >= 3) {
        NotificationService().scheduleStreakEncouragement(_streakDays);
      }
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
    setState(() {
      _highlightTimer = false;
    });

    switch (need) {
      case 'Focus':
        setState(() {
          _needSuggestions = [
            _Suggestion(Icons.timer_outlined, 'Try a focus timer session', AppColors.sageGreen, () => _navigate(context, const TimerScreen())),
            _Suggestion(Icons.music_note_outlined, 'Listen to instrumental focus music', AppColors.softIndigo, () {
              AppNavigationService().setMusicRecommendation('Focus mood: Try Focus Mode / Instrumental calm.');
              AppNavigationService().requestTab(AppTabTarget.music);
            }),
            _Suggestion(Icons.air_rounded, 'Start with a short breathing exercise', AppColors.warmCoral, () => _navigate(context, const BreathingScreen())),
          ];
        });
        break;
      case 'Calm':
        setState(() {
          _needSuggestions = [
            _Suggestion(Icons.air_rounded, 'Try a slow breathing session', AppColors.softIndigo, () => _navigate(context, const BreathingScreen())),
            _Suggestion(Icons.music_note_outlined, 'Play gentle calming music', AppColors.sageGreen, () {
              AppNavigationService().setMusicRecommendation('Calm mood: Try Soft Tamil Evenings or Deep Calm.');
              AppNavigationService().requestTab(AppTabTarget.music);
            }),
            _Suggestion(Icons.edit_note_rounded, 'Write down what\'s on your mind', AppColors.orangeE2814d, () => _navigate(context, const JournalScreen())),
          ];
        });
        break;
      case 'Release thoughts':
        setState(() {
          _needSuggestions = [
            _Suggestion(Icons.edit_note_rounded, 'Open your journal and write freely', AppColors.orangeE2814d, () => _navigate(context, const JournalScreen())),
            _Suggestion(Icons.air_rounded, 'Breathe first, then write', AppColors.softIndigo, () => _navigate(context, const BreathingScreen())),
            _Suggestion(Icons.people_outline_rounded, 'Share with the community', AppColors.warmCoral, () => AppNavigationService().requestTab(AppTabTarget.community)),
          ];
        });
        break;
      case 'Rest':
        setState(() {
          _needSuggestions = [
            _Suggestion(Icons.nightlight_outlined, 'Log your sleep and wind down', AppColors.warmCoral, () => _navigate(context, const SleepTrackerScreen())),
            _Suggestion(Icons.music_note_outlined, 'Play soft ambient tracks', AppColors.sageGreen, () {
              AppNavigationService().setMusicRecommendation('Rest mood: Try Sleep Mode and soft ambient tracks.');
              AppNavigationService().requestTab(AppTabTarget.music);
            }),
            _Suggestion(Icons.air_rounded, 'A gentle breathing session before rest', AppColors.softIndigo, () => _navigate(context, const BreathingScreen())),
          ];
        });
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
                    RepaintBoundary(child: _buildActivityCard(context)),
                    const SizedBox(height: 28),
                    RepaintBoundary(
                      child: DailyCheckin(
                        onNeedSelected: _handleNeedSelection,
                      ),
                    ),
                    if (_needSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                          border: Border.all(
                            color: AppColors.softIndigo.withValues(alpha: 0.25),
                          ),
                          boxShadow: AppColors.subtleShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.softIndigo),
                                const SizedBox(width: 8),
                                Text(
                                  'Here are some things you can try',
                                  style: AppTypography.captionC(context).copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._needSuggestions.map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GestureDetector(
                                onTap: s.onTap,
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: s.color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(s.icon, color: s.color, size: 16),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        s.label,
                                        style: AppTypography.captionC(context).copyWith(
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.tertiary(context),
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            )),
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
                    QuickActionButton(
                      icon: Icons.insights_rounded,
                      label: 'Insights',
                      iconColor: AppColors.coralDa5e5a,
                      onTap: () => _navigate(context, const InsightsScreen()),
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
            child: UserPreferencesService().avatarConfigMap != null
                ? ValueListenableBuilder<bool>(
                    valueListenable: ActivityService().isWalking,
                    builder: (_, walking, __) => CustomAvatar(
                      config: AvatarConfig.fromMap(UserPreferencesService().avatarConfigMap!),
                      size: 54,
                      isWalking: walking,
                    ),
                  )
                : Image.network(
                    UserPreferencesService().getAvatarUrl(),
                    fit: BoxFit.cover,
                    cacheWidth: 108,
                    cacheHeight: 108,
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
                            size: 24,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(BuildContext context) {
    return ValueListenableBuilder<ActivityData>(
      valueListenable: ActivityService().todayData,
      builder: (context, data, _) {
        final hasPermission = ActivityService().permissionGranted.value;

        // Permission prompt card
        if (!hasPermission && !_activityPermissionDismissed) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: AppColors.softIndigo.withValues(alpha: 0.2)),
              boxShadow: AppColors.subtleShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.directions_walk_rounded, color: AppColors.sageGreen, size: 20),
                    const SizedBox(width: 8),
                    Text('Track your walks', style: AppTypography.captionC(context).copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _activityPermissionDismissed = true),
                      child: Icon(Icons.close_rounded, size: 18, color: AppColors.tertiary(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Allow location access to track steps, distance, and calories.',
                  style: AppTypography.captionC(context),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final granted = await ActivityService().requestPermissions();
                    if (granted) {
                      await ActivityService().startTracking();
                      if (mounted) setState(() {});
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.softIndigo,
                      borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                    ),
                    child: Text('Allow', style: AppTypography.buttonText(color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        }

        if (!hasPermission) return const SizedBox.shrink();

        // Activity data card
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppColors.sageGreen.withValues(alpha: 0.2)),
            boxShadow: AppColors.subtleShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_walk_rounded, color: AppColors.sageGreen, size: 20),
                  const SizedBox(width: 8),
                  Text('Today\'s Activity', style: AppTypography.captionC(context).copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  ValueListenableBuilder<bool>(
                    valueListenable: ActivityService().isWalking,
                    builder: (_, walking, __) {
                      if (!walking) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.sageGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Walking', style: AppTypography.caption(color: AppColors.sageGreen).copyWith(fontSize: 10)),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _activityStat(context, Icons.directions_walk_rounded, '${data.steps}', 'Steps'),
                  _activityStat(context, Icons.straighten_rounded, '${data.distanceKm.toStringAsFixed(1)} km', 'Distance'),
                  _activityStat(context, Icons.local_fire_department_rounded, data.calories.toStringAsFixed(0), 'Calories'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _activityStat(BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.sageGreen, size: 20),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.uiLabelC(context).copyWith(fontWeight: FontWeight.w600, fontSize: 15)),
        Text(label, style: AppTypography.captionC(context).copyWith(fontSize: 10)),
      ],
    );
  }
}

class _Suggestion {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _Suggestion(this.icon, this.label, this.color, this.onTap);
}
