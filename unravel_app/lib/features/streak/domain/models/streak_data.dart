import 'package:freezed_annotation/freezed_annotation.dart';
part 'streak_data.freezed.dart';
part 'streak_data.g.dart';

@freezed
class StreakData with _$StreakData {
  const factory StreakData({
    @Default(0) int currentStreak,
    @Default(0) int longestStreak,
    DateTime? lastLoginDate,
    @Default([]) List<DateTime> loginDates,
  }) = _StreakData;

  factory StreakData.fromJson(Map<String, dynamic> json) => _$StreakDataFromJson(json);
}
