import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import '../services/notification_service.dart';
import '../widgets/custom_avatar.dart';
import '../services/activity_service.dart';
import '../widgets/avatar_renderer.dart';
import 'dart:math';
import 'breathing_screen.dart';
import 'sleep_tracker_screen.dart';
import 'journal_screen.dart';
import 'timer_screen.dart';
import 'insights_screen.dart';
import 'podcast_screen.dart';
import 'gratitude_screen.dart';
import 'safety_net_screen.dart';

/// Unravel Home Screen - the emotional dashboard.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _recoveryScore = 1.0;
  List<double> _moodData = List<double>.filled(7, 0.5);
  int _streakDays = 0;
  bool _activityPermissionDismissed = false;

  List<_Suggestion> _needSuggestions = [];
  bool _highlightTimer = false;
  late final String _dailyQuote;

  static const List<String> _quotes = [
    '"The wound is the place where the light enters you." — Rumi',
    '"You are allowed to be both a masterpiece and a work in progress."',
    '"Be gentle with yourself. You\'re doing the best you can."',
    '"Almost everything will work again if you unplug it for a few minutes — including you." — Anne Lamott',
    '"You don\'t have to control your thoughts. You just have to stop letting them control you." — Dan Millman',
    '"Happiness is not something ready-made. It comes from your own actions." — Dalai Lama',
    '"The only way out is through." — Robert Frost',
    '"Not all storms come to disrupt your life; some come to clear your path."',
    '"Breathe. Let go. And remind yourself that this very moment is the only one you know you have for sure." — Oprah Winfrey',
    '"You are not your thoughts. You are the awareness behind them."',
    '"The present moment is filled with joy and happiness. If you are attentive, you will see it." — Thich Nhat Hanh',
    '"Healing doesn\'t mean the damage never existed. It means the damage no longer controls your life."',
    '"What lies behind us and what lies before us are tiny matters compared to what lies within us." — Ralph Waldo Emerson',
    '"Start where you are. Use what you have. Do what you can." — Arthur Ashe',
    '"Self-care is not self-indulgence. Self-care is self-preservation." — Audre Lorde',
    '"Your calm mind is the ultimate weapon against your challenges." — Bryant McGill',
    '"In the middle of difficulty lies opportunity." — Albert Einstein',
    '"You yourself, as much as anybody in the entire universe, deserve your love and affection." — Buddha',
    '"It is during our darkest moments that we must focus to see the light." — Aristotle',
    '"Nothing can dim the light that shines from within." — Maya Angelou',
    '"The greatest glory in living lies not in never falling, but in rising every time we fall." — Nelson Mandela',
    '"Courage is not the absence of fear, but the triumph over it."',
    '"Every morning brings new potential, but if you dwell on the misfortunes of the day before, you tend to overlook tremendous opportunities."',
    '"Rest is not idleness, and to lie sometimes on the grass under trees on a summer\'s day is by no means a waste of time." — John Lubbock',
    '"Gratitude turns what we have into enough."',
    '"The best time to plant a tree was 20 years ago. The second best time is now." — Chinese Proverb',
    '"Love yourself first and everything else falls into line." — Lucille Ball',
    '"Peace comes from within. Do not seek it without." — Buddha',
    '"Discipline is the bridge between goals and accomplishment." — Jim Rohn',
    '"You are braver than you believe, stronger than you seem, and smarter than you think." — A.A. Milne',
    '"Life isn\'t about waiting for the storm to pass. It\'s about learning to dance in the rain." — Vivian Greene',
    '"What we think, we become." — Buddha',
    '"The only impossible journey is the one you never begin." — Tony Robbins',
    '"Growth is uncomfortable; that\'s why so few people do it."',
    '"Kindness is a language which the deaf can hear and the blind can see." — Mark Twain',
    '"Do not let what you cannot do interfere with what you can do." — John Wooden',
    '"Talk to yourself like someone you love." — Brene Brown',
    '"The quieter you become, the more you can hear." — Ram Dass',
    '"Small steps in the right direction can turn out to be the biggest step of your life."',
    '"You don\'t have to see the whole staircase, just take the first step." — Martin Luther King Jr.',
    '"Your mental health is a priority. Your happiness is essential. Your self-care is a necessity."',
    '"Inhale courage, exhale fear."',
    '"When you can\'t control what\'s happening, challenge yourself to control how you respond."',
    '"Be patient with yourself. Nothing in nature blooms all year."',
    '"You are enough just as you are."',
    '"The sun himself is weak when he first rises, and gathers strength and courage as the day gets on." — Charles Dickens',
    '"We must be willing to let go of the life we planned so as to have the life that is waiting for us." — Joseph Campbell',
    '"Feelings are much like waves. We can\'t stop them from coming, but we can choose which ones to surf." — Jonatan Martensson',
    '"Sometimes the most productive thing you can do is relax." — Mark Black',
    '"One small crack does not mean that you are broken. It means that you were put to the test and you didn\'t fall apart."',
    '"Every day may not be good, but there is something good in every day."',
    '"What consumes your mind controls your life."',
    '"Owning our story and loving ourselves through that process is the bravest thing we\'ll ever do." — Brene Brown',
    '"Out of your vulnerabilities will come your strength." — Sigmund Freud',
    '"Don\'t believe everything you think."',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    _dailyQuote = _quotes[Random(seed).nextInt(_quotes.length)];
    _loadData();
  }

  Future<void> _loadData() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final db = DatabaseService();
    final scoreFuture = db
        .getLatestRecoveryScore(user.$id)
        .catchError((_) => 100.0);
    final moodFuture = db
        .getMoodEntries(user.$id, days: 7)
        .catchError((_) => LocalRowList(rows: <LocalRow>[]));
    final streakFuture = db
        .getOrCreateStreak(user.$id)
        .catchError(
          (_) => LocalRow(
            $id: user.$id,
            data: <String, dynamic>{'currentStreak': 0},
          ),
        );

    final results = await Future.wait<dynamic>([
      scoreFuture,
      moodFuture,
      streakFuture,
    ]);
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

  void _handleNeedSelection(String need) {
    setState(() {
      _highlightTimer = false;
    });

    switch (need) {
      case 'Focus':
        setState(() {
          _needSuggestions = [
            _Suggestion(
              Icons.timer_outlined,
              'Try a focus timer session',
              AppColors.sageGreen,
              () => _navigate(context, const TimerScreen()),
            ),
            _Suggestion(
              Icons.music_note_outlined,
              'Listen to instrumental focus music',
              AppColors.softIndigo,
              () {
                AppNavigationService().setMusicRecommendation(
                  'Focus mood: Try Focus Mode / Instrumental calm.',
                );
                AppNavigationService().requestTab(AppTabTarget.music);
              },
            ),
            _Suggestion(
              Icons.air_rounded,
              'Start with a short breathing exercise',
              AppColors.warmCoral,
              () => _navigate(context, const BreathingScreen()),
            ),
            _Suggestion(
              Icons.av_timer_rounded,
              'Pomodoro Focus — 25-min deep work',
              AppColors.orangeE2814d,
              () => _navigate(context, const TimerScreen()),
            ),
            _Suggestion(
              Icons.favorite_border_rounded,
              'Gratitude Check — count your wins',
              AppColors.sageGreen,
              () => _navigate(context, const GratitudeScreen()),
            ),
            _Suggestion(
              Icons.edit_note_rounded,
              'Journal Intentions — set your focus',
              AppColors.softIndigo,
              () => _navigate(context, const JournalScreen()),
            ),
          ];
        });
        break;
      case 'Calm':
        setState(() {
          _needSuggestions = [
            _Suggestion(
              Icons.air_rounded,
              'Try a slow breathing session',
              AppColors.softIndigo,
              () => _navigate(context, const BreathingScreen()),
            ),
            _Suggestion(
              Icons.music_note_outlined,
              'Play gentle calming music',
              AppColors.sageGreen,
              () {
                AppNavigationService().setMusicRecommendation(
                  'Calm mood: Try Soft Tamil Evenings or Deep Calm.',
                );
                AppNavigationService().requestTab(AppTabTarget.music);
              },
            ),
            _Suggestion(
              Icons.edit_note_rounded,
              'Write down what\'s on your mind',
              AppColors.orangeE2814d,
              () => _navigate(context, const JournalScreen()),
            ),
            _Suggestion(
              Icons.accessibility_new_rounded,
              'Body Scan — release tension slowly',
              AppColors.warmCoral,
              () => _navigate(context, const BreathingScreen()),
            ),
            _Suggestion(
              Icons.visibility_outlined,
              '5-4-3-2-1 Grounding — anchor yourself',
              AppColors.sageGreen,
              () => _navigate(context, const BreathingScreen()),
            ),
            _Suggestion(
              Icons.headphones_rounded,
              'Listen to a calming Podcast',
              AppColors.softIndigo,
              () => _navigate(context, const PodcastScreen()),
            ),
          ];
        });
        break;
      case 'Release thoughts':
        setState(() {
          _needSuggestions = [
            _Suggestion(
              Icons.edit_note_rounded,
              'Open your journal and write freely',
              AppColors.orangeE2814d,
              () => _navigate(context, const JournalScreen()),
            ),
            _Suggestion(
              Icons.air_rounded,
              'Breathe first, then write',
              AppColors.softIndigo,
              () => _navigate(context, const BreathingScreen()),
            ),
            _Suggestion(
              Icons.people_outline_rounded,
              'Share with the community',
              AppColors.warmCoral,
              () => AppNavigationService().requestTab(AppTabTarget.community),
            ),
            _Suggestion(
              Icons.favorite_border_rounded,
              'Gratitude & Wins — celebrate progress',
              AppColors.sageGreen,
              () => _navigate(context, const GratitudeScreen()),
            ),
            _Suggestion(
              Icons.shield_outlined,
              'Safety Net — reach out for support',
              AppColors.warmCoral,
              () => _navigate(context, const SafetyNetScreen()),
            ),
            _Suggestion(
              Icons.square_outlined,
              'Box Breathing — steady your mind',
              AppColors.softIndigo,
              () => _navigate(context, const BreathingScreen()),
            ),
          ];
        });
        break;
      case 'Rest':
        setState(() {
          _needSuggestions = [
            _Suggestion(
              Icons.nightlight_outlined,
              'Log your sleep and wind down',
              AppColors.warmCoral,
              () => _navigate(context, const SleepTrackerScreen()),
            ),
            _Suggestion(
              Icons.music_note_outlined,
              'Play soft ambient tracks',
              AppColors.sageGreen,
              () {
                AppNavigationService().setMusicRecommendation(
                  'Rest mood: Try Sleep Mode and soft ambient tracks.',
                );
                AppNavigationService().requestTab(AppTabTarget.music);
              },
            ),
            _Suggestion(
              Icons.air_rounded,
              'A gentle breathing session before rest',
              AppColors.softIndigo,
              () => _navigate(context, const BreathingScreen()),
            ),
            _Suggestion(
              Icons.headphones_rounded,
              'Sleep Stories Podcast — drift off gently',
              AppColors.orangeE2814d,
              () => _navigate(context, const PodcastScreen()),
            ),
            _Suggestion(
              Icons.accessibility_new_rounded,
              'Body Scan — relax every muscle',
              AppColors.sageGreen,
              () => _navigate(context, const BreathingScreen()),
            ),
            _Suggestion(
              Icons.favorite_border_rounded,
              'Gratitude Before Bed — end on a high',
              AppColors.softIndigo,
              () => _navigate(context, const GratitudeScreen()),
            ),
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
                      child: MoodSelector(onMoodSaved: (_) => _loadData()),
                    ),
                    const SizedBox(height: 16),
                    // ── Daily Quote ──
                    Center(
                      child: Text(
                        _dailyQuote,
                        style: AppTypography.emotionalTextC(context).copyWith(
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                        .animate()
                        .fadeIn(
                          duration: const Duration(milliseconds: 700),
                          curve: AppTheme.gentleCurve,
                        ),
                    const SizedBox(height: 28),
                    RepaintBoundary(
                      child: RecoveryScoreCard(score: _recoveryScore),
                    ),
                    const SizedBox(height: 28),
                    RepaintBoundary(child: _buildActivityCard(context)),
                    const SizedBox(height: 28),
                    RepaintBoundary(
                      child: DailyCheckin(onNeedSelected: _handleNeedSelection),
                    ),
                    if (_needSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusCard,
                          ),
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
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 16,
                                  color: AppColors.softIndigo,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Here are some things you can try',
                                  style: AppTypography.captionC(
                                    context,
                                  ).copyWith(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._needSuggestions.map(
                              (s) => Padding(
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          s.icon,
                                          color: s.color,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          s.label,
                                          style: AppTypography.captionC(context)
                                              .copyWith(
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
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    Text(
                      'Guided Sessions',
                      style: AppTypography.sectionHeadingC(context),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildGuidedSessionCard(
                            context,
                            icon: Icons.self_improvement_rounded,
                            label: '10-min Calm',
                            color: AppColors.softIndigo,
                            onTap: () => _navigate(context, const PodcastScreen()),
                          ),
                          _buildGuidedSessionCard(
                            context,
                            icon: Icons.air_rounded,
                            label: 'Quick Breathe',
                            color: AppColors.sageGreen,
                            onTap: () => _navigate(context, const BreathingScreen()),
                          ),
                          _buildGuidedSessionCard(
                            context,
                            icon: Icons.nightlight_outlined,
                            label: 'Sleep Wind-Down',
                            color: AppColors.warmCoral,
                            onTap: () => _navigate(context, const PodcastScreen()),
                          ),
                          _buildGuidedSessionCard(
                            context,
                            icon: Icons.directions_walk_rounded,
                            label: 'Mindful Walk',
                            color: AppColors.orangeE2814d,
                            onTap: () => _navigate(context, const PodcastScreen()),
                          ),
                          _buildGuidedSessionCard(
                            context,
                            icon: Icons.wb_sunny_outlined,
                            label: 'Morning Reset',
                            color: AppColors.sageGreen,
                            onTap: () => _navigate(context, const BreathingScreen()),
                          ),
                        ],
                      ),
                    ),
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
                      onTap: () =>
                          _navigate(context, const SleepTrackerScreen()),
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
                    QuickActionButton(
                      icon: Icons.podcasts_rounded,
                      label: 'Podcast',
                      iconColor: AppColors.softIndigo,
                      onTap: () => _navigate(context, const PodcastScreen()),
                    ),
                    QuickActionButton(
                      icon: Icons.emoji_events_outlined,
                      label: 'Gratitude',
                      iconColor: AppColors.amberFdb903,
                      onTap: () =>
                          _navigate(context, const GratitudeScreen()),
                    ),
                    QuickActionButton(
                      icon: Icons.sos_rounded,
                      label: 'Safety Net',
                      iconColor: AppColors.coralDa5e5a,
                      onTap: () => _navigate(context, const SafetyNetScreen()),
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
                        onTap: () => AppNavigationService().requestTab(
                          AppTabTarget.community,
                        ),
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
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Opacity(
                  opacity: 0.7,
                  child: Text(
                    _dailyQuote,
                    style: AppTypography.subtitleC(
                      context,
                    ).copyWith(fontStyle: FontStyle.italic, fontSize: 12),
                  ),
                ),
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
                      config: AvatarConfig.fromMap(
                        UserPreferencesService().avatarConfigMap!,
                      ),
                      size: 54,
                      isWalking: walking,
                    ),
                  )
                : _buildAvatarWidget(54),
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
              border: Border.all(
                color: AppColors.softIndigo.withValues(alpha: 0.2),
              ),
              boxShadow: AppColors.subtleShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.directions_walk_rounded,
                      color: AppColors.sageGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Track your walks',
                      style: AppTypography.captionC(
                        context,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _activityPermissionDismissed = true),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.tertiary(context),
                      ),
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
                    final granted = await ActivityService()
                        .requestPermissions();
                    if (granted) {
                      await ActivityService().startTracking();
                      if (mounted) setState(() {});
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.softIndigo,
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusButton,
                      ),
                    ),
                    child: Text(
                      'Allow',
                      style: AppTypography.buttonText(color: Colors.white),
                    ),
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
            border: Border.all(
              color: AppColors.sageGreen.withValues(alpha: 0.2),
            ),
            boxShadow: AppColors.subtleShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.directions_walk_rounded,
                    color: AppColors.sageGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Today\'s Activity',
                    style: AppTypography.captionC(
                      context,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  ValueListenableBuilder<bool>(
                    valueListenable: ActivityService().isWalking,
                    builder: (_, walking, __) {
                      if (!walking) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.sageGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Walking',
                          style: AppTypography.caption(
                            color: AppColors.sageGreen,
                          ).copyWith(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _activityStat(
                    context,
                    Icons.directions_walk_rounded,
                    '${data.steps}',
                    'Steps',
                  ),
                  _activityStat(
                    context,
                    Icons.straighten_rounded,
                    '${data.distanceKm.toStringAsFixed(1)} km',
                    'Distance',
                  ),
                  _activityStat(
                    context,
                    Icons.local_fire_department_rounded,
                    data.calories.toStringAsFixed(0),
                    'Calories',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _activityStat(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, color: AppColors.sageGreen, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.uiLabelC(
            context,
          ).copyWith(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        Text(
          label,
          style: AppTypography.captionC(context).copyWith(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildGuidedSessionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 120,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
            ),
            boxShadow: AppColors.subtleShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTypography.captionC(context).copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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
