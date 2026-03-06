import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/report_provider.dart';
import '../../domain/models/report_data.dart';
import '../widgets/combined_overlay_chart.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(reportRangeProvider);
    final reportData = ref.watch(reportDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<ReportRange>(
              segments: const [
                ButtonSegment(value: ReportRange.daily, label: Text('Daily')),
                ButtonSegment(value: ReportRange.weekly, label: Text('Weekly')),
              ],
              selected: {range},
              onSelectionChanged: (selected) {
                ref.read(reportRangeProvider.notifier).state = selected.first;
              },
            ),
          ),
          Expanded(
            child: reportData.when(
              data: (data) => data.isEmpty
                  ? const Center(child: Text('No data yet. Start logging your mood!'))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CombinedOverlayChart(dataPoints: data),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
