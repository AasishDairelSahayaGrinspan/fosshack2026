import 'dart:developer' as developer;
import 'package:appwrite/appwrite.dart';

import 'appwrite_constants.dart';
import 'appwrite_service.dart';
import 'local_data_service.dart';

/// Aggregates daily wellness metrics and syncs to the wellness_logs collection.
class WellnessAnalyticsService {
  static final WellnessAnalyticsService _instance =
      WellnessAnalyticsService._internal();
  factory WellnessAnalyticsService() => _instance;
  WellnessAnalyticsService._internal();

  static const String _tag = 'WellnessAnalyticsService';

  final Databases _db = AppwriteService().databases;
  static const String _dbId = AppwriteConstants.databaseId;

  // Mood label → metrics mapping
  static const Map<String, Map<String, int>> _moodMetrics = {
    'Calm': {'mood': 4, 'stress': 1, 'energy': 3, 'anxiety': 1},
    'Okay': {'mood': 3, 'stress': 2, 'energy': 3, 'anxiety': 2},
    'Low': {'mood': 2, 'stress': 3, 'energy': 2, 'anxiety': 3},
    'Anxious': {'mood': 2, 'stress': 4, 'energy': 2, 'anxiety': 4},
    'Overwhelmed': {'mood': 1, 'stress': 5, 'energy': 1, 'anxiety': 5},
  };

  /// Called after mood check-in, sleep log, journal save, or breathing session.
  /// Aggregates all daily data and pushes/updates a wellness_log entry for today.
  Future<void> syncDailyWellnessLog(String userId) async {
    try {
      final now = DateTime.now();
      final todayKey =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final local = LocalDataService();
      await local.init();

      // 1. Get today's mood entries → compute average mood
      final allMoods = local.getMoodEntries(userId);
      final todayMoods = allMoods.where((e) {
        final ts = DateTime.tryParse(e['timestamp'] as String? ?? '');
        return ts != null &&
            ts.year == now.year &&
            ts.month == now.month &&
            ts.day == now.day;
      }).toList();

      double avgMoodValue = 3.0; // default
      double avgStress = 2.0;
      double avgEnergy = 3.0;
      double avgAnxiety = 2.0;

      if (todayMoods.isNotEmpty) {
        // mood is stored as 0.0–1.0 in the app; map to 1–5
        final moodValues = todayMoods
            .map((e) => ((e['mood'] as num?)?.toDouble() ?? 0.5))
            .toList();
        final rawAvg =
            moodValues.reduce((a, b) => a + b) / moodValues.length;
        avgMoodValue = (rawAvg * 4.0 + 1.0).clamp(1.0, 5.0); // 0→1, 1→5

        // Try to derive stress/energy/anxiety from emoji labels
        final metrics = <Map<String, int>>[];
        for (final mood in todayMoods) {
          final emoji = mood['emoji'] as String? ?? '';
          // Map common emoji labels
          final label = _mapEmojiToLabel(emoji);
          if (_moodMetrics.containsKey(label)) {
            metrics.add(_moodMetrics[label]!);
          }
        }
        if (metrics.isNotEmpty) {
          avgStress = metrics
                  .map((m) => m['stress']!.toDouble())
                  .reduce((a, b) => a + b) /
              metrics.length;
          avgEnergy = metrics
                  .map((m) => m['energy']!.toDouble())
                  .reduce((a, b) => a + b) /
              metrics.length;
          avgAnxiety = metrics
                  .map((m) => m['anxiety']!.toDouble())
                  .reduce((a, b) => a + b) /
              metrics.length;
        }
      }

      // 2. Get today's sleep hours
      final allSleep = local.getSleepLogs(userId);
      final todaySleep = allSleep.firstWhere(
        (l) => (l['date'] as String?) == todayKey,
        orElse: () => <String, dynamic>{},
      );
      final sleepHours =
          (todaySleep['hours'] as num?)?.toDouble() ?? 0.0;

      // 3. Check if user journaled today
      final allJournals = local.getJournalEntries(userId);
      final todayJournals = allJournals.where((e) {
        final ts = DateTime.tryParse(e['timestamp'] as String? ?? '');
        return ts != null &&
            ts.year == now.year &&
            ts.month == now.month &&
            ts.day == now.day;
      }).toList();

      final didJournal = todayJournals.isNotEmpty;
      final journalContent = todayJournals.isNotEmpty
          ? (todayJournals.first['content'] as String? ?? '')
          : '';
      final journalSentiment =
          didJournal ? _computeBasicSentiment(journalContent) : 0.0;

      // 4. Check if user did breathing/exercise
      final allBreathing = local.getBreathingLogs(userId);
      final todayBreathing = allBreathing.where((e) {
        final ts = DateTime.tryParse(e['timestamp'] as String? ?? '');
        return ts != null &&
            ts.year == now.year &&
            ts.month == now.month &&
            ts.day == now.day;
      }).toList();
      final didExercise = todayBreathing.isNotEmpty ? 1 : 0;

      // 5. Compute wellness_score as weighted average (1–5 scale)
      // Weights: mood 30%, sleep 25%, stress_inv 15%, energy 10%, anxiety_inv 10%, journal 5%, exercise 5%
      final sleepScore = (sleepHours / 8.0 * 5.0).clamp(1.0, 5.0);
      final stressInv = (6.0 - avgStress).clamp(1.0, 5.0);
      final anxietyInv = (6.0 - avgAnxiety).clamp(1.0, 5.0);
      final journalScore = didJournal ? 4.0 : 2.0;
      final exerciseScore = didExercise == 1 ? 4.5 : 2.0;

      final wellnessScore = (avgMoodValue * 0.30 +
              sleepScore * 0.25 +
              stressInv * 0.15 +
              avgEnergy * 0.10 +
              anxietyInv * 0.10 +
              journalScore * 0.05 +
              exerciseScore * 0.05)
          .clamp(1.0, 5.0);

      final logData = <String, dynamic>{
        'user_id': userId,
        'log_date': now.toIso8601String(),
        'mood': avgMoodValue.round().clamp(1, 5),
        'sleep_hours': double.parse(sleepHours.toStringAsFixed(1)),
        'stress': avgStress.round().clamp(1, 5),
        'energy': avgEnergy.round().clamp(1, 5),
        'anxiety': avgAnxiety.round().clamp(1, 5),
        'exercise': didExercise,
        'journaling': didJournal ? 'yes' : 'no',
        'journal_sentiment':
            double.parse(journalSentiment.toStringAsFixed(2)),
        'wellness_score': double.parse(wellnessScore.toStringAsFixed(2)),
        'created_at': now.toIso8601String(),
      };

      // 6. Upsert to Appwrite: check if today's entry exists
      await _upsertWellnessLog(userId, todayKey, logData);

      // 7. Cache locally
      final cachedLogs = local.getGenericList('wellness_logs_$userId');
      cachedLogs.removeWhere((l) {
        final d = DateTime.tryParse(l['log_date'] as String? ?? '');
        return d != null &&
            d.year == now.year &&
            d.month == now.month &&
            d.day == now.day;
      });
      cachedLogs.add(logData);
      await local.saveGenericList('wellness_logs_$userId', cachedLogs);

      developer.log('Synced wellness log for $todayKey: score=$wellnessScore',
          name: _tag);
    } catch (e, st) {
      developer.log('syncDailyWellnessLog failed',
          name: _tag, error: e, stackTrace: st);
    }
  }

  Future<void> _upsertWellnessLog(
    String userId,
    String todayKey,
    Map<String, dynamic> logData,
  ) async {
    try {
      // Try to find existing doc for today
      final result = await _db.listDocuments(
        databaseId: _dbId,
        collectionId: AppwriteConstants.wellnessLogsCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.greaterThanEqual(
              'log_date', '${todayKey}T00:00:00.000'),
          Query.lessThan('log_date', '${todayKey}T23:59:59.999'),
          Query.limit(1),
        ],
      );

      if (result.documents.isNotEmpty) {
        // Update existing
        await _db.updateDocument(
          databaseId: _dbId,
          collectionId: AppwriteConstants.wellnessLogsCollection,
          documentId: result.documents.first.$id,
          data: logData,
        );
      } else {
        // Create new
        await _db.createDocument(
          databaseId: _dbId,
          collectionId: AppwriteConstants.wellnessLogsCollection,
          documentId: ID.unique(),
          data: logData,
          permissions: [
            Permission.read(Role.user(userId)),
            Permission.write(Role.user(userId)),
          ],
        );
      }
    } on AppwriteException catch (e) {
      developer.log('_upsertWellnessLog remote failed: ${e.message}',
          name: _tag);
    } catch (e) {
      developer.log('_upsertWellnessLog remote failed', name: _tag, error: e);
    }
  }

  /// Get recent wellness logs for display
  Future<List<Map<String, dynamic>>> getWellnessLogs(
    String userId, {
    int days = 7,
  }) async {
    final local = LocalDataService();
    await local.init();

    // Try Appwrite first
    try {
      final cutoff =
          DateTime.now().subtract(Duration(days: days)).toIso8601String();
      final result = await _db.listDocuments(
        databaseId: _dbId,
        collectionId: AppwriteConstants.wellnessLogsCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.greaterThan('log_date', cutoff),
          Query.orderDesc('log_date'),
          Query.limit(days),
        ],
      );

      if (result.documents.isNotEmpty) {
        final logs = result.documents
            .map((d) => Map<String, dynamic>.from(d.data))
            .toList();
        await local.saveGenericList('wellness_logs_$userId', logs);
        return logs;
      }
    } on AppwriteException catch (e) {
      developer.log('getWellnessLogs remote failed: ${e.message}',
          name: _tag);
    } catch (e) {
      developer.log('getWellnessLogs remote failed', name: _tag, error: e);
    }

    // Fallback to local
    final cached = local.getGenericList('wellness_logs_$userId');
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return cached.where((l) {
      final d = DateTime.tryParse(l['log_date'] as String? ?? '');
      return d != null && d.isAfter(cutoff);
    }).toList();
  }

  String _mapEmojiToLabel(String emoji) {
    // Map emoji strings to our mood labels
    final lower = emoji.toLowerCase();
    if (lower.contains('calm') || lower.contains('peaceful')) return 'Calm';
    if (lower.contains('okay') || lower.contains('neutral')) return 'Okay';
    if (lower.contains('low') || lower.contains('sad')) return 'Low';
    if (lower.contains('anxious') || lower.contains('worried')) return 'Anxious';
    if (lower.contains('overwhelmed') || lower.contains('stressed')) {
      return 'Overwhelmed';
    }
    return 'Okay'; // default
  }

  double _computeBasicSentiment(String text) {
    if (text.isEmpty) return 0.0;

    const positiveWords = {
      'happy', 'grateful', 'calm', 'peaceful', 'good', 'great', 'wonderful',
      'amazing', 'love', 'joy', 'hopeful', 'better', 'smile', 'kind',
      'thankful', 'blessed', 'relaxed', 'proud', 'excited', 'beautiful',
    };
    const negativeWords = {
      'sad', 'anxious', 'stressed', 'worried', 'angry', 'frustrated',
      'tired', 'exhausted', 'lonely', 'scared', 'hurt', 'depressed',
      'overwhelmed', 'hopeless', 'painful', 'awful', 'terrible', 'bad',
    };

    final words = text.toLowerCase().split(RegExp(r'\W+'));
    int positive = 0;
    int negative = 0;
    for (final w in words) {
      if (positiveWords.contains(w)) positive++;
      if (negativeWords.contains(w)) negative++;
    }
    final total = positive + negative;
    if (total == 0) return 0.0;
    return ((positive - negative) / total).clamp(-1.0, 1.0);
  }
}
