import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/appwrite_constants.dart';
import '../../../../core/providers/core_providers.dart';
import '../models/journal_entry.dart';

class JournalNotifier extends AsyncNotifier<List<JournalEntry>> {
  @override
  Future<List<JournalEntry>> build() async {
    final box = await Hive.openBox('journal_entries');
    final entries = <JournalEntry>[];
    for (final key in box.keys) {
      final data = Map<String, dynamic>.from(box.get(key) as Map);
      entries.add(JournalEntry.fromJson(data));
    }
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  Future<void> saveEntry({
    required String content,
    required List<String> tags,
    String? moodEntryId,
  }) async {
    final entry = JournalEntry(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      content: content,
      tags: tags,
      moodEntryId: moodEntryId,
    );

    final box = await Hive.openBox('journal_entries');
    await box.put(entry.id, entry.toJson());

    try {
      final databases = ref.read(appwriteDatabasesProvider);
      await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.journalEntriesCollection,
        documentId: entry.id,
        data: {
          'content': entry.content,
          'tags': entry.tags,
          'moodLogId': entry.moodEntryId,
          'timestamp': entry.timestamp.toIso8601String(),
        },
      );
    } catch (_) {}

    final current = state.value ?? [];
    state = AsyncData([entry, ...current]);
  }
}

final journalProvider = AsyncNotifierProvider<JournalNotifier, List<JournalEntry>>(
  () => JournalNotifier(),
);
