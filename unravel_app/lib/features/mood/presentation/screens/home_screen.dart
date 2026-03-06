import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../streak/domain/providers/streak_provider.dart';
import '../../../recovery/domain/providers/recovery_provider.dart';
import '../../domain/providers/mood_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger initial data loads
    Future.microtask(() {
      ref.read(moodHistoryProvider.notifier);
    });
  }

  Color _quadrantColor(String quadrant) {
    switch (quadrant) {
      case 'highEnergyPleasant':
        return AppColors.highEnergyPleasant;
      case 'highEnergyUnpleasant':
        return AppColors.highEnergyUnpleasant;
      case 'lowEnergyUnpleasant':
        return AppColors.lowEnergyUnpleasant;
      case 'lowEnergyPleasant':
        return AppColors.lowEnergyPleasant;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final streakData = ref.watch(streakProvider);
    final moodHistory = ref.watch(moodHistoryProvider);
    final recovery = ref.watch(recoveryProvider);
    final noAdviceMode = ref.watch(noAdviceModeProvider);

    final displayName = authState.valueOrNull?.displayName ?? 'there';

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.go('/mood/history'),
            tooltip: 'Mood History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome text
            Text(
              'Welcome back, $displayName!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.motivationalQuotes[
                  DateTime.now().day % AppStrings.motivationalQuotes.length],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: 24),

            // Streak badge
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_fire_department,
                    color: Colors.orange, size: 32),
                title: Text(
                  '${streakData.value?.currentStreak ?? 0}-day streak',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                subtitle: Text(
                  'Longest: ${streakData.value?.longestStreak ?? 0} days',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick mood check-in button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () => context.go('/mood'),
                icon: const Icon(Icons.add_reaction_outlined),
                label: const Text('Mood Check-in'),
                style: FilledButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recent mood entries
            Text(
              'Recent Moods',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            moodHistory.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('No mood entries yet. Start your first check-in!'),
                      ),
                    ),
                  );
                }
                final recent = entries.take(3).toList();
                return Column(
                  children: recent.map((entry) {
                    final color = _quadrantColor(entry.quadrant);
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.2),
                          child: Icon(Icons.circle, color: color, size: 16),
                        ),
                        title: Text(entry.emotionWord),
                        subtitle: Text(
                          _formatTimestamp(entry.timestamp),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: entry.note != null && entry.note!.isNotEmpty
                            ? const Icon(Icons.note, size: 16, color: AppColors.textHint)
                            : null,
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Could not load moods: $e'),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recovery score summary card
            Text(
              'Recovery Score',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            recovery.when(
              data: (score) {
                if (score == null) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('No recovery data available yet.'),
                      ),
                    ),
                  );
                }
                return Card(
                  child: InkWell(
                    onTap: () => context.go('/recovery'),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: score.score / 100,
                                  strokeWidth: 6,
                                  backgroundColor: AppColors.surfaceVariant,
                                  color: score.score >= 70
                                      ? AppColors.success
                                      : score.score >= 40
                                          ? AppColors.warning
                                          : AppColors.error,
                                ),
                                Text(
                                  '${score.score.round()}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recovery Score',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  'Based on ${score.windowDays}-day window',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Could not load recovery score: $e'),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Navigation to breathing/music if advice mode is on
            if (!noAdviceMode) ...[
              Text(
                'Tools',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: () => context.go('/breathing'),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(Icons.air, size: 32, color: AppColors.primary),
                              SizedBox(height: 8),
                              Text('Breathing'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: () => context.go('/music'),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(Icons.music_note, size: 32, color: AppColors.primary),
                              SizedBox(height: 8),
                              Text('Music'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
  }
}
