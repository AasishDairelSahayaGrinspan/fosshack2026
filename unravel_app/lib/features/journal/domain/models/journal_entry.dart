import 'package:freezed_annotation/freezed_annotation.dart';
part 'journal_entry.freezed.dart';
part 'journal_entry.g.dart';

enum JournalTag { sleep, caffeine, social, exercise, medication, therapy, other }

@freezed
class JournalEntry with _$JournalEntry {
  const factory JournalEntry({
    required String id,
    required DateTime timestamp,
    required String content,
    @Default([]) List<String> tags,
    String? moodEntryId,
    @Default(false) bool synced,
  }) = _JournalEntry;

  factory JournalEntry.fromJson(Map<String, dynamic> json) => _$JournalEntryFromJson(json);
}
