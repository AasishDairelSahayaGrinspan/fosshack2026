import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/providers/mood_provider.dart';

class MoodHistoryScreen extends ConsumerWidget {
  const MoodHistoryScreen({super.key});

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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodHistory = ref.watch(moodHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood History'),
      ),
      body: moodHistory.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mood, size: 64, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text('No mood entries yet.'),
                  SizedBox(height: 8),
                  Text(
                    'Start tracking your moods to see them here.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final color = _quadrantColor(entry.quadrant);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                  title: Text(
                    entry.emotionWord,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTimestamp(entry.timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textHint,
                            ),
                      ),
                      if (entry.note != null && entry.note!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            entry.note!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: entry.note != null && entry.note!.isNotEmpty,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error loading mood history: $e'),
            ],
          ),
        ),
      ),
    );
  }
}
