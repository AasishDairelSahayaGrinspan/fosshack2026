import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/constants/appwrite_constants.dart';
import '../../../../core/constants/circumplex_data.dart';
import '../models/mood_entry.dart';
import '../models/circumplex_position.dart';

// Current circumplex position (what user is selecting right now)
class CircumplexNotifier extends StateNotifier<CircumplexPosition> {
  CircumplexNotifier() : super(const CircumplexPosition());

  void selectQuadrant(String quadrant) {
    state = CircumplexPosition(selectedQuadrant: quadrant);
  }

  void selectEmotion(EmotionWord word) {
    state = CircumplexPosition(
      valence: word.valence,
      arousal: word.arousal,
      selectedWord: word.label,
      selectedQuadrant: word.quadrant.name,
    );
  }

  void reset() {
    state = const CircumplexPosition();
  }
}

final circumplexStateProvider = StateNotifierProvider<CircumplexNotifier, CircumplexPosition>(
  (ref) => CircumplexNotifier(),
);

// Current mood (last submitted)
final currentMoodProvider = StateProvider<MoodEntry?>((ref) => null);

// Mood history
class MoodHistoryNotifier extends AsyncNotifier<List<MoodEntry>> {
  @override
  Future<List<MoodEntry>> build() async {
    final box = await Hive.openBox('mood_entries');
    final entries = <MoodEntry>[];
    for (final key in box.keys) {
      final data = Map<String, dynamic>.from(box.get(key) as Map);
      entries.add(MoodEntry.fromJson(data));
    }
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  Future<void> submitMood({
    required double valence,
    required double arousal,
    required String emotionWord,
    required String quadrant,
    String? note,
  }) async {
    final entry = MoodEntry(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      valence: valence,
      arousal: arousal,
      emotionWord: emotionWord,
      quadrant: quadrant,
      note: note,
    );

    // Save to Hive (offline-first)
    final box = await Hive.openBox('mood_entries');
    await box.put(entry.id, entry.toJson());

    // Update current mood
    ref.read(currentMoodProvider.notifier).state = entry;

    // Try sync to Appwrite
    try {
      final databases = ref.read(appwriteDatabasesProvider);
      await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.moodLogsCollection,
        documentId: ID.unique(),
        data: {
          'valence': entry.valence,
          'arousal': entry.arousal,
          'emotionWord': entry.emotionWord,
          'quadrant': entry.quadrant,
          'note': entry.note,
          'timestamp': entry.timestamp.toIso8601String(),
        },
      );
    } catch (_) {
      // Will sync later
    }

    // Update history state
    final current = state.value ?? [];
    state = AsyncData([entry, ...current]);
  }
}

final moodHistoryProvider = AsyncNotifierProvider<MoodHistoryNotifier, List<MoodEntry>>(
  () => MoodHistoryNotifier(),
);
