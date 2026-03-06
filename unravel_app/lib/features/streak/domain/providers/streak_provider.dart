import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/utils/date_utils.dart';
import '../models/streak_data.dart';

class StreakNotifier extends AsyncNotifier<StreakData> {
  @override
  Future<StreakData> build() async {
    final box = await Hive.openBox('streak');
    final rawDates = box.get('loginDates', defaultValue: <dynamic>[]) as List;
    final dates = rawDates.map((d) => DateTime.parse(d.toString())).toList();
    return _calculateStreak(dates);
  }

  Future<void> recordLogin() async {
    final today = DateTime.now().toDateOnly();
    final box = await Hive.openBox('streak');
    final rawDates = box.get('loginDates', defaultValue: <dynamic>[]) as List;
    final dates = rawDates.map((d) => DateTime.parse(d.toString())).toList();

    if (!dates.any((d) => d.toDateOnly().isSameDay(today))) {
      dates.add(today);
      await box.put('loginDates', dates.map((d) => d.toIso8601String()).toList());
    }
    state = AsyncData(_calculateStreak(dates));
  }

  StreakData _calculateStreak(List<DateTime> dates) {
    if (dates.isEmpty) {
      return const StreakData();
    }

    final sorted = dates.map((d) => d.toDateOnly()).toList()..sort();
    final today = DateTime.now().toDateOnly();

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 1;

    // Calculate longest streak
    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff == 1) {
        tempStreak++;
      } else if (diff > 1) {
        if (tempStreak > longestStreak) longestStreak = tempStreak;
        tempStreak = 1;
      }
    }
    if (tempStreak > longestStreak) longestStreak = tempStreak;

    // Calculate current streak (from today backwards)
    if (sorted.last.isSameDay(today) || sorted.last.isSameDay(today.subtract(const Duration(days: 1)))) {
      currentStreak = 1;
      for (int i = sorted.length - 2; i >= 0; i--) {
        final diff = sorted[i + 1].difference(sorted[i]).inDays;
        if (diff == 1) {
          currentStreak++;
        } else {
          break;
        }
      }
    }

    return StreakData(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastLoginDate: sorted.last,
      loginDates: sorted,
    );
  }
}

final streakProvider = AsyncNotifierProvider<StreakNotifier, StreakData>(
  () => StreakNotifier(),
);
