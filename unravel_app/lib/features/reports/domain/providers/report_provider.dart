import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../mood/domain/providers/mood_provider.dart';
import '../../../recovery/domain/providers/recovery_provider.dart';
import '../models/report_data.dart';

final reportRangeProvider = StateProvider<ReportRange>((ref) => ReportRange.weekly);

final reportDataProvider = FutureProvider<List<ReportDataPoint>>((ref) async {
  final range = ref.watch(reportRangeProvider);
  final moods = ref.watch(moodHistoryProvider).value ?? [];
  final recoveryScores = ref.watch(recoveryHistoryProvider).value ?? [];

  final days = range == ReportRange.daily ? 1 : 7;
  final cutoff = DateTime.now().subtract(Duration(days: days));

  final filteredMoods = moods.where((m) => m.timestamp.isAfter(cutoff)).toList();

  final dataPoints = <ReportDataPoint>[];
  for (final mood in filteredMoods) {
    final matchingScore = recoveryScores.where(
      (r) => r.date.year == mood.timestamp.year &&
             r.date.month == mood.timestamp.month &&
             r.date.day == mood.timestamp.day,
    ).firstOrNull;

    dataPoints.add(ReportDataPoint(
      date: mood.timestamp,
      moodValence: mood.valence,
      moodQuadrant: mood.quadrant,
      recoveryScore: matchingScore?.score,
    ));
  }

  dataPoints.sort((a, b) => a.date.compareTo(b.date));
  return dataPoints;
});
