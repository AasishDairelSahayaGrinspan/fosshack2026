import 'package:freezed_annotation/freezed_annotation.dart';
part 'mood_entry.freezed.dart';
part 'mood_entry.g.dart';

@freezed
class MoodEntry with _$MoodEntry {
  const factory MoodEntry({
    required String id,
    required DateTime timestamp,
    required double valence,
    required double arousal,
    required String emotionWord,
    required String quadrant,
    String? journalId,
    String? note,
    @Default(false) bool synced,
  }) = _MoodEntry;

  factory MoodEntry.fromJson(Map<String, dynamic> json) => _$MoodEntryFromJson(json);
}
