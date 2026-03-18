import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/gradient_background.dart';
import '../widgets/circular_progress_card.dart';
import '../widgets/mini_bar_chart.dart';
import '../widgets/habit_streak_card.dart';
import '../widgets/stat_pill.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/local_data_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  // Insights data
  double _moodConsistency = 0.5;
  List<double> _sleepHours = List.filled(7, 0);
  List<String> _sleepLabels = [];
  int _moodLogCount = 0;
  int _breathingSessions = 0;
  int _journalEntries = 0;
  int _songsListened = 0;
  int _communityInteractions = 0;

  // Habits data (14 days)
  List<bool> _moodHabit = List.filled(14, false);
  List<bool> _sleepHabit = List.filled(14, false);
  List<bool> _breathingHabit = List.filled(14, false);
  List<bool> _journalHabit = List.filled(14, false);
  int _moodStreak = 0;
  int _sleepStreak = 0;
  int _breathingStreak = 0;
  int _journalStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  String _dayKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Future<void> _loadAll() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    final userId = user.$id;
    final db = DatabaseService();
    final local = LocalDataService();
    final now = DateTime.now();

    // --- Insights ---
    // Mood entries for 7 days
    final moodResult = await db.getMoodEntries(userId, days: 7);
    final moodValues = moodResult.rows.map((r) => (r.data['mood'] as num).toDouble()).toList();
    _moodLogCount = moodValues.length;

    // Mood consistency
    if (moodValues.isNotEmpty) {
      final mean = moodValues.reduce((a, b) => a + b) / moodValues.length;
      final variance = moodValues.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / moodValues.length;
      final stddev = sqrt(variance);
      _moodConsistency = (1.0 - (stddev / 0.5)).clamp(0.0, 1.0);
    }

    // Sleep
    final sleepLogs = await db.getSleepLogs(userId, days: 7);
    _sleepHours = sleepLogs.map((l) => (l['hours'] as num?)?.toDouble() ?? 0.0).toList();
    _sleepLabels = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return _dayNames[day.weekday - 1];
    });

    // Breathing
    final breathingLogs = local.getBreathingLogs(userId);
    final weekAgo = now.subtract(const Duration(days: 7));
    _breathingSessions = breathingLogs.where((l) {
      final ts = DateTime.tryParse(l['timestamp'] as String? ?? '');
      return ts != null && ts.isAfter(weekAgo);
    }).length;

    // Journal
    final journalEntries = local.getJournalEntries(userId);
    _journalEntries = journalEntries.where((e) {
      final ts = DateTime.tryParse(e['timestamp'] as String? ?? '');
      return ts != null && ts.isAfter(weekAgo);
    }).length;

    // Songs
    final songs = local.getListenedSongs(userId);
    _songsListened = songs.where((s) {
      final ts = DateTime.tryParse(s['timestamp'] as String? ?? '');
      return ts != null && ts.isAfter(weekAgo);
    }).length;

    // Community
    final posts = local.getCommunityPosts();
    _communityInteractions = 0;
    for (final post in posts) {
      final ts = DateTime.tryParse(post['timestamp'] as String? ?? '');
      if (ts != null && ts.isAfter(weekAgo)) {
        if (post['userId'] == userId) _communityInteractions++;
        final comments = post['comments'] as List<dynamic>? ?? [];
        for (final c in comments) {
          if (c is Map && c['userId'] == userId) {
            final cts = DateTime.tryParse(c['timestamp'] as String? ?? '');
            if (cts != null && cts.isAfter(weekAgo)) _communityInteractions++;
          }
        }
      }
    }

    // --- Habits (14 days) ---
    final allMoods = local.getMoodEntries(userId);
    final allSleep = local.getSleepLogs(userId);
    final allBreathing = local.getBreathingLogs(userId);
    final allJournal = local.getJournalEntries(userId);

    _moodHabit = _computeHabitDays(allMoods, 'timestamp', 14, now);
    _sleepHabit = _computeHabitDaysFromDateKey(allSleep, 'date', 14, now);
    _breathingHabit = _computeHabitDays(allBreathing, 'timestamp', 14, now);
    _journalHabit = _computeHabitDays(allJournal, 'timestamp', 14, now);

    _moodStreak = _countStreak(_moodHabit);
    _sleepStreak = _countStreak(_sleepHabit);
    _breathingStreak = _countStreak(_breathingHabit);
    _journalStreak = _countStreak(_journalHabit);

    if (mounted) setState(() {});
  }

  List<bool> _computeHabitDays(List<Map<String, dynamic>> entries, String tsKey, int days, DateTime now) {
    final daySet = <String>{};
    for (final e in entries) {
      final ts = DateTime.tryParse(e[tsKey] as String? ?? '');
      if (ts != null) daySet.add(_dayKey(ts));
    }
    return List.generate(days, (i) {
      final day = now.subtract(Duration(days: days - 1 - i));
      return daySet.contains(_dayKey(day));
    });
  }

  List<bool> _computeHabitDaysFromDateKey(List<Map<String, dynamic>> entries, String dateKey, int days, DateTime now) {
    final daySet = <String>{};
    for (final e in entries) {
      final date = e[dateKey] as String?;
      final hours = (e['hours'] as num?)?.toDouble() ?? 0;
      if (date != null && hours > 0) daySet.add(date);
    }
    return List.generate(days, (i) {
      final day = now.subtract(Duration(days: days - 1 - i));
      return daySet.contains(_dayKey(day));
    });
  }

  int _countStreak(List<bool> days) {
    int streak = 0;
    for (int i = days.length - 1; i >= 0; i--) {
      if (days[i]) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  String _dateRange() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 6));
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[start.month - 1]} ${start.day} - ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: GradientBackground(
        colors: AppColors.bgGradient(context),
        secondaryColors: AppColors.bgGradientAlt(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                TabBar(
                  labelColor: AppColors.softIndigo,
                  unselectedLabelColor: AppColors.tertiary(context),
                  indicatorColor: AppColors.softIndigo,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: AppTypography.uiLabelC(context),
                  unselectedLabelStyle: AppTypography.captionC(context),
                  tabs: const [
                    Tab(text: 'Insights'),
                    Tab(text: 'Habits'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildInsightsTab(context),
                      _buildHabitsTab(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary(context).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.arrow_back_rounded, color: AppColors.secondary(context), size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Text('Insights', style: AppTypography.sectionHeadingC(context)),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(BuildContext context) {
    final avgSleep = _sleepHours.isEmpty ? 0.0 : _sleepHours.reduce((a, b) => a + b) / _sleepHours.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your week at a glance', style: AppTypography.heroHeadingC(context))
              .animate().fadeIn(duration: const Duration(milliseconds: 500), curve: AppTheme.gentleCurve),
          const SizedBox(height: 4),
          Text(_dateRange(), style: AppTypography.captionC(context))
              .animate().fadeIn(duration: const Duration(milliseconds: 500)),
          const SizedBox(height: 20),

          // Mood consistency
          CircularProgressCard(
            progress: _moodConsistency,
            title: 'Mood Consistency',
            subtitle: _moodConsistency > 0.7
                ? 'Your mood has been steady this week.'
                : _moodConsistency > 0.4
                    ? 'Some ups and downs — that\'s okay.'
                    : 'Your mood varied a lot. Be gentle with yourself.',
            progressColor: AppColors.softIndigo,
          ).animate(delay: const Duration(milliseconds: 100)).fadeIn(duration: const Duration(milliseconds: 400)).slideY(begin: 0.03, end: 0),

          const SizedBox(height: 14),

          // Sleep
          Text('Sleep Overview', style: AppTypography.uiLabelC(context)),
          const SizedBox(height: 8),
          MiniBarChart(
            values: _sleepHours,
            maxValue: 10,
            labels: _sleepLabels,
            barColor: AppColors.warmCoral,
            caption: 'Avg: ${avgSleep.toStringAsFixed(1)}h per night',
          ).animate(delay: const Duration(milliseconds: 200)).fadeIn(duration: const Duration(milliseconds: 400)).slideY(begin: 0.03, end: 0),

          const SizedBox(height: 20),

          // App engagement
          Text('App Engagement', style: AppTypography.uiLabelC(context)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatPill(icon: Icons.emoji_emotions_outlined, value: '$_moodLogCount', label: 'moods', color: AppColors.softIndigo),
              StatPill(icon: Icons.air_rounded, value: '$_breathingSessions', label: 'breaths', color: AppColors.sageGreen),
              StatPill(icon: Icons.edit_note_rounded, value: '$_journalEntries', label: 'journals', color: AppColors.orangeE2814d),
              StatPill(icon: Icons.music_note_outlined, value: '$_songsListened', label: 'songs', color: AppColors.warmCoral),
            ],
          ).animate(delay: const Duration(milliseconds: 300)).fadeIn(duration: const Duration(milliseconds: 400)),

          const SizedBox(height: 20),

          // Community
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: AppColors.dividerColor(context), width: 0.8),
            ),
            child: Row(
              children: [
                Icon(Icons.people_outline_rounded, color: AppColors.softIndigo, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _communityInteractions > 0
                        ? 'You supported others $_communityInteractions time${_communityInteractions == 1 ? '' : 's'} this week.'
                        : 'Share some kindness in the community this week.',
                    style: AppTypography.captionC(context),
                  ),
                ),
              ],
            ),
          ).animate(delay: const Duration(milliseconds: 400)).fadeIn(duration: const Duration(milliseconds: 400)),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHabitsTab(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your habits', style: AppTypography.heroHeadingC(context))
              .animate().fadeIn(duration: const Duration(milliseconds: 500), curve: AppTheme.gentleCurve),
          const SizedBox(height: 4),
          Text('Last 14 days', style: AppTypography.captionC(context)),
          const SizedBox(height: 20),

          HabitStreakCard(
            icon: Icons.emoji_emotions_outlined,
            name: 'Mood Check-in',
            streak: _moodStreak,
            last14Days: _moodHabit,
            accentColor: AppColors.softIndigo,
            message: _moodStreak > 3 ? 'Great consistency! Keep checking in.' : 'Log your mood daily to build this habit.',
          ).animate(delay: const Duration(milliseconds: 100)).fadeIn(duration: const Duration(milliseconds: 400)).slideY(begin: 0.03, end: 0),

          HabitStreakCard(
            icon: Icons.nightlight_outlined,
            name: 'Sleep Tracking',
            streak: _sleepStreak,
            last14Days: _sleepHabit,
            accentColor: AppColors.warmCoral,
            message: _sleepStreak > 3 ? 'Your sleep routine is strong.' : 'Track your sleep to see patterns.',
          ).animate(delay: const Duration(milliseconds: 200)).fadeIn(duration: const Duration(milliseconds: 400)).slideY(begin: 0.03, end: 0),

          HabitStreakCard(
            icon: Icons.air_rounded,
            name: 'Breathing',
            streak: _breathingStreak,
            last14Days: _breathingHabit,
            accentColor: AppColors.sageGreen,
            message: _breathingStreak > 3 ? 'Wonderful breathing practice.' : 'Even one session a day helps.',
          ).animate(delay: const Duration(milliseconds: 300)).fadeIn(duration: const Duration(milliseconds: 400)).slideY(begin: 0.03, end: 0),

          HabitStreakCard(
            icon: Icons.edit_note_rounded,
            name: 'Journal',
            streak: _journalStreak,
            last14Days: _journalHabit,
            accentColor: AppColors.orangeE2814d,
            message: _journalStreak > 3 ? 'Your journaling habit is growing.' : 'Write a few lines each day.',
          ).animate(delay: const Duration(milliseconds: 400)).fadeIn(duration: const Duration(milliseconds: 400)).slideY(begin: 0.03, end: 0),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
