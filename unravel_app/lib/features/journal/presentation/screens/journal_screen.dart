import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/providers/journal_provider.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  Color _tagColor(String tag) {
    switch (tag) {
      case 'sleep':
        return Colors.indigo;
      case 'caffeine':
        return Colors.brown;
      case 'social':
        return Colors.pink;
      case 'exercise':
        return Colors.teal;
      case 'medication':
        return Colors.deepPurple;
      case 'therapy':
        return Colors.cyan;
      case 'other':
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(DateTime timestamp) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[timestamp.month - 1]} ${timestamp.day}, ${timestamp.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalState = ref.watch(journalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/journal/new'),
        child: const Icon(Icons.add),
      ),
      body: journalState.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 64, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text('No journal entries yet.'),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to write your first entry.',
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
              final preview = entry.content.length > 100
                  ? '${entry.content.substring(0, 100)}...'
                  : entry.content;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(entry.timestamp),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.textHint,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        preview,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (entry.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: entry.tags.map((tag) {
                            final color = _tagColor(tag);
                            return Chip(
                              label: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                ),
                              ),
                              backgroundColor: color.withOpacity(0.1),
                              side: BorderSide.none,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
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
              Text('Error loading journal: $e'),
            ],
          ),
        ),
      ),
    );
  }
}
