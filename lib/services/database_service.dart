import 'dart:developer' as developer;
import 'dart:math';

import 'package:appwrite/appwrite.dart';

import 'appwrite_constants.dart';
import 'appwrite_service.dart';
import 'auth_service.dart';
import 'local_data_service.dart';
import 'storage_service.dart';

class LocalRow {
  final String $id;
  final Map<String, dynamic> data;
  LocalRow({required this.$id, required this.data});
}

class LocalRowList {
  final List<LocalRow> rows;
  LocalRowList({required this.rows});
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _tag = 'DatabaseService';

  final Databases _db = AppwriteService().databases;
  static const String _dbId = AppwriteConstants.databaseId;

  Future<String> _ensureUserId(String userId) async {
    await LocalDataService().init();
    return userId;
  }

  String _newId([String prefix = 'id']) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}';

  String _dayKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  DateTime _startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // ──────────────────────────────────────────────
  // USER PROFILE
  // ──────────────────────────────────────────────

  Future<LocalRow> createUserProfile({
    required String userId,
    required String name,
    String? ageGroup,
    List<String>? concerns,
    String? sleepSchedule,
    double moodBaseline = 0.5,
    String? avatarUrl,
    int hairStyle = 0,
    int skinTone = 0,
    int outfitColor = 0,
    List<String>? musicLanguages,
  }) async {
    await _ensureUserId(userId);
    final data = <String, dynamic>{
      'userId': userId,
      'name': name,
      'ageGroup': ageGroup,
      'concerns': concerns ?? <String>[],
      'sleepSchedule': sleepSchedule,
      'moodBaseline': moodBaseline,
      'avatarUrl': avatarUrl,
      'hairStyle': hairStyle,
      'skinTone': skinTone,
      'outfitColor': outfitColor,
      'musicLanguages': musicLanguages ?? <String>[],
      'createdAt': DateTime.now().toIso8601String(),
      'communityPreference': 'yes',
    };

    // Write to Appwrite
    try {
      await _db.createDocument(
        databaseId: _dbId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId,
        data: data,
        permissions: [
          Permission.read(Role.user(userId)),
          Permission.write(Role.user(userId)),
        ],
      );
    } on AppwriteException catch (e) {
      if (e.code == 409) {
        // Document already exists, update instead
        try {
          await _db.updateDocument(
            databaseId: _dbId,
            collectionId: AppwriteConstants.usersCollection,
            documentId: userId,
            data: data,
          );
        } catch (updateErr) {
          developer.log('createUserProfile update fallback failed', name: _tag, error: updateErr);
        }
      } else {
        developer.log('createUserProfile remote failed: ${e.message}', name: _tag);
      }
    } catch (e) {
      developer.log('createUserProfile remote failed', name: _tag, error: e);
    }

    // Cache locally
    await LocalDataService().saveUserPrefs(userId, data);
    return LocalRow($id: userId, data: data);
  }

  Future<LocalRow> getUserProfile(String userId) async {
    await _ensureUserId(userId);

    // Try Appwrite first
    try {
      final doc = await _db.getDocument(
        databaseId: _dbId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId,
      );
      final data = Map<String, dynamic>.from(doc.data);
      await LocalDataService().saveUserPrefs(userId, data);
      return LocalRow($id: userId, data: data);
    } on AppwriteException catch (e) {
      developer.log('getUserProfile remote failed: ${e.message}', name: _tag);
    } catch (e) {
      developer.log('getUserProfile remote failed', name: _tag, error: e);
    }

    // Fallback to local
    final data = LocalDataService().getUserPrefs(userId);
    if (data.isEmpty) {
      throw Exception('User profile not found');
    }
    return LocalRow($id: userId, data: data);
  }

  Future<LocalRow> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _ensureUserId(userId);
    final existing = LocalDataService().getUserPrefs(userId);
    existing.addAll(data);

    // Write to Appwrite
    try {
      await _db.updateDocument(
        databaseId: _dbId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId,
        data: data,
      );
    } on AppwriteException catch (e) {
      developer.log('updateUserProfile remote failed: ${e.message}', name: _tag);
    } catch (e) {
      developer.log('updateUserProfile remote failed', name: _tag, error: e);
    }

    // Cache locally
    await LocalDataService().saveUserPrefs(userId, existing);
    return LocalRow($id: userId, data: existing);
  }

  // ──────────────────────────────────────────────
  // MOOD ENTRIES + RECOVERY
  // ──────────────────────────────────────────────

  Future<LocalRow> saveMoodEntry({
    required String userId,
    required double mood,
    required String emoji,
    String? note,
  }) async {
    await _ensureUserId(userId);
    final row = <String, dynamic>{
      'userId': userId,
      'mood': mood,
      'emoji': emoji,
      'note': note,
      'timestamp': DateTime.now().toIso8601String(),
    };

    String docId = _newId('mood');

    // Write to Appwrite
    try {
      final doc = await _db.createDocument(
        databaseId: _dbId,
        collectionId: AppwriteConstants.moodEntriesCollection,
        documentId: ID.unique(),
        data: row,
        permissions: [
          Permission.read(Role.user(userId)),
          Permission.write(Role.user(userId)),
        ],
      );
      docId = doc.$id;
    } on AppwriteException catch (e) {
      developer.log('saveMoodEntry remote failed: ${e.message}', name: _tag);
    } catch (e) {
      developer.log('saveMoodEntry remote failed', name: _tag, error: e);
    }

    // Cache locally
    row['id'] = docId;
    final entries = LocalDataService().getMoodEntries(userId);
    entries.add(row);
    entries.sort((a, b) => (a['timestamp'] as String).compareTo(b['timestamp'] as String));
    await LocalDataService().saveMoodEntries(userId, entries);
    await _recomputeRecoveryFromMood(userId);
    await LocalDataService().addAnalytics(
      'mood_saved',
      payload: <String, dynamic>{'userId': userId, 'mood': mood},
    );
    return LocalRow($id: docId, data: row);
  }

  Future<LocalRowList> getMoodEntries(
    String userId, {
    int days = 7,
  }) async {
    await _ensureUserId(userId);

    // Try to fetch from Appwrite
    try {
      final now = DateTime.now();
      final cutoff = now.subtract(Duration(days: days + 1));
      final result = await _db.listDocuments(
        databaseId: _dbId,
        collectionId: AppwriteConstants.moodEntriesCollection,
        queries: [
          Query.equal('userId', userId),
          Query.greaterThan('timestamp', cutoff.toIso8601String()),
          Query.orderDesc('timestamp'),
          Query.limit(500),
        ],
      );

      if (result.documents.isNotEmpty) {
        // Update local cache
        final remoteEntries = result.documents
            .map((doc) => <String, dynamic>{...doc.data, 'id': doc.$id})
            .toList();
        final localEntries = LocalDataService().getMoodEntries(userId);
        // Merge remote into local (remote wins for same id)
        final remoteIds = remoteEntries.map((e) => e['id']).toSet();
        final merged = <Map<String, dynamic>>[
          ...remoteEntries,
          ...localEntries.where((e) => !remoteIds.contains(e['id'])),
        ];
        merged.sort((a, b) => (a['timestamp'] as String).compareTo(b['timestamp'] as String));
        await LocalDataService().saveMoodEntries(userId, merged);
      }
    } on AppwriteException catch (e) {
      developer.log('getMoodEntries remote failed: ${e.message}', name: _tag);
    } catch (e) {
      developer.log('getMoodEntries remote failed', name: _tag, error: e);
    }

    // Build aggregated day data from local cache
    final entries = LocalDataService().getMoodEntries(userId);
    final now = DateTime.now();
    final dayScores = <String, List<double>>{};

    for (final entry in entries) {
      final ts = DateTime.tryParse((entry['timestamp'] as String?) ?? '');
      if (ts == null) continue;
      if (now.difference(ts).inDays > days + 1) continue;
      final key = _dayKey(ts);
      dayScores.putIfAbsent(key, () => <double>[]);
      dayScores[key]!.add((entry['mood'] as num).toDouble());
    }

    final rows = <LocalRow>[];
    for (int i = days - 1; i >= 0; i--) {
      final day = _startOfDay(now.subtract(Duration(days: i)));
      final key = _dayKey(day);
      final values = dayScores[key] ?? <double>[];
      final avg = values.isEmpty
          ? 0.5
          : values.reduce((a, b) => a + b) / values.length;
      rows.add(
        LocalRow(
          $id: 'mood_$key',
          data: <String, dynamic>{
            'mood': avg.clamp(0.0, 1.0),
            'timestamp': day.toIso8601String(),
            'day': key,
          },
        ),
      );
    }
    return LocalRowList(rows: rows);
  }

  Future<void> _recomputeRecoveryFromMood(String userId) async {
    final entries = LocalDataService().getMoodEntries(userId);
    final prefs = LocalDataService().getUserPrefs(userId);
    final baseline = ((prefs['moodBaseline'] as num?)?.toDouble() ?? 0.5)
        .clamp(0.0, 1.0);

    final byDay = <String, List<double>>{};
    for (final entry in entries) {
      final ts = DateTime.tryParse((entry['timestamp'] as String?) ?? '');
      if (ts == null) continue;
      final key = _dayKey(ts);
      byDay.putIfAbsent(key, () => <double>[]);
      byDay[key]!.add((entry['mood'] as num).toDouble());
    }
    final keys = byDay.keys.toList()..sort();
    double score = (50.0 + (baseline * 35.0)).clamp(0.0, 100.0);
    double? prevAvg;
    final history = <Map<String, dynamic>>[];

    for (final key in keys) {
      final values = byDay[key]!;
      final avg = values.reduce((a, b) => a + b) / values.length;

      final baselineShift = (avg - baseline) * 22.0;
      final trend = prevAvg == null ? 0.0 : (avg - prevAvg) * 18.0;
      final volatilityPenalty =
          prevAvg == null ? 0.0 : (avg - prevAvg).abs() * 6.0;
      final consistencyBonus = min(values.length, 3) * 1.2;
      final delta =
          baselineShift + trend + consistencyBonus - volatilityPenalty;

      final nextScore = (score + delta).clamp(0.0, 100.0);
      // Smooth updates to avoid abrupt score spikes from a single mood entry.
      score = ((score * 0.88) + (nextScore * 0.12)).clamp(0.0, 100.0);
      prevAvg = avg;

      history.add(<String, dynamic>{
        'date': key,
        'score': double.parse(score.toStringAsFixed(2)),
        'avgMood': double.parse(avg.toStringAsFixed(3)),
        'baseline': double.parse(baseline.toStringAsFixed(3)),
        'entries': values.length,
      });
    }

    if (history.isEmpty) {
      history.add(<String, dynamic>{
        'date': _dayKey(DateTime.now()),
        'score': double.parse(score.toStringAsFixed(2)),
        'avgMood': baseline,
        'baseline': baseline,
        'entries': 0,
      });
    }
    await LocalDataService().saveRecoveryHistory(userId, history);
  }

  // ──────────────────────────────────────────────
  // JOURNAL
  // ──────────────────────────────────────────────

  Future<LocalRow> saveJournalEntry({
    required String userId,
    required String content,
    String? moodTag,
    String? prompt,
    List<String>? mediaIds,
  }) async {
    await _ensureUserId(userId);
    final row = <String, dynamic>{
      'userId': userId,
      'content': content,
      'moodTag': moodTag,
      'prompt': prompt,
      'mediaIds': mediaIds ?? <String>[],
      'timestamp': DateTime.now().toIso8601String(),
    };

    String docId = _newId('journal');

    // Write to Appwrite
    try {
      final doc = await _db.createDocument(
        databaseId: _dbId,
        collectionId: AppwriteConstants.journalEntriesCollection,
        documentId: ID.unique(),
        data: row,
        permissions: [
          Permission.read(Role.user(userId)),
          Permission.write(Role.user(userId)),
        ],
      );
      docId = doc.$id;
    } on AppwriteException catch (e) {
      developer.log('saveJournalEntry remote failed: ${e.message}', name: _tag);
    } catch (e) {
      developer.log('saveJournalEntry remote failed', name: _tag, error: e);
    }

    // Cache locally
    row['id'] = docId;
    final entries = LocalDataService().getJournalEntries(userId);
    entries.insert(0, row);
    await LocalDataService().saveJournalEntries(userId, entries);
    await LocalDataService().addAnalytics(
      'journal_saved',
      payload: <String, dynamic>{'userId': userId},
    );
    return LocalRow($id: docId, data: row);
  }

  Future<LocalRowList> getJournalEntries(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    await _ensureUserId(userId);

    // Try Appwrite
    try {
      final result = await _db.listDocuments(
        databaseId: _dbId,
        collectionId: AppwriteConstants.journalEntriesCollection,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('timestamp'),
          Query.limit(limit),
          Query.offset(offset),
        ],
      );

      if (result.documents.isNotEmpty) {
        final remoteEntries = result.documents
            .map((doc) => <String, dynamic>{...doc.data, 'id': doc.$id})
            .toList();
        if (offset == 0) {
          // Merge into local cache
          final localEntries = LocalDataService().getJournalEntries(userId);
          final remoteIds = remoteEntries.map((e) => e['id']).toSet();
          final merged = <Map<String, dynamic>>[
            ...remoteEntries,
            ...localEntries.where((e) => !remoteIds.contains(e['id'])),
          ];
          merged.sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String));
          await LocalDataService().saveJournalEntries(userId, merged);
        }
        return LocalRowList(
          rows: remoteEntries
              .map((e) => LocalRow($id: e['id'] as String, data: e))
              .toList(),
        );
      }
    } on AppwriteException catch (e) {
      developer.log('getJournalEntries remote failed: ${e.message}', name: _tag);
    } catch (e) {
      developer.log('getJournalEntries remote failed', name: _tag, error: e);
    }

    // Fallback to local
    final entries = LocalDataService().getJournalEntries(userId);
    final sliced = entries.skip(offset).take(limit).toList();
    return LocalRowList(
      rows: sliced
          .map((e) => LocalRow($id: e['id'] as String, data: e))
          .toList(),
    );
  }

  Future<void> deleteJournalEntry(String rowId) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    // Delete from Appwrite
    try {
      await _db.deleteDocument(
        databaseId: _dbId,
        collectionId: AppwriteConstants.journalEntriesCollection,
        documentId: rowId,
      );
    } on AppwriteException catch (e) {
      developer.log('deleteJournalEntry remote failed: ${e.message}', name: _tag);
    } catch (e) {
      developer.log('deleteJournalEntry remote failed', name: _tag, error: e);
    }

    // Remove from local cache
    final entries = LocalDataService().getJournalEntries(user.$id);
    entries.removeWhere((e) => e['id'] == rowId);
    await LocalDataService().saveJournalEntries(user.$id, entries);
  }

  // ──────────────────────────────────────────────
  // STREAK
  // ──────────────────────────────────────────────

  Future<LocalRow> getOrCreateStreak(String userId) async {
    await _ensureUserId(userId);

    // Try Appwrite first
    try {
      final doc = await _db.getDocument(
        databaseId: _dbId,
        collectionId: AppwriteConstants.streaksCollection,
        documentId: userId,
      );
      final data = Map<String, dynamic>.from(doc.data);
      await LocalDataService().saveStreak(userId, data);
      return LocalRow($id: userId, data: data);
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        // Create new streak document
        final streak = <String, dynamic>{
          'userId': userId,
          'currentStreak': 0,
          'longestStreak': 0,
          'lastCheckIn': null,
        };
        try {
          await _db.createDocument(
            databaseId: _dbId,
            collectionId: AppwriteConstants.streaksCollection,
            documentId: userId,
            data: streak,
            permissions: [
              Permission.read(Role.user(userId)),
              Permission.write(Role.user(userId)),
            ],
          );
        } catch (_) {}
        await LocalDataService().saveStreak(userId, streak);
        return LocalRow($id: userId, data: streak);
      }
      developer.log('getOrCreateStreak remote failed: ${e.message}', name: _tag);
    } catch (e) {
      developer.log('getOrCreateStreak remote failed', name: _tag, error: e);
    }

    // Fallback to local
    final streak = LocalDataService().getStreak(userId);
    await LocalDataService().saveStreak(userId, streak);
    return LocalRow($id: userId, data: streak);
  }

  Future<LocalRow> updateStreak(String userId) async {
    await _ensureUserId(userId);
    final streak = LocalDataService().getStreak(userId);
    final now = DateTime.now();
    final today = _startOfDay(now);
    int currentStreak = (streak['currentStreak'] as num?)?.toInt() ?? 0;
    int longestStreak = (streak['longestStreak'] as num?)?.toInt() ?? 0;

    final rawLast = streak['lastCheckIn'] as String?;
    if (rawLast != null) {
      final last = DateTime.tryParse(rawLast);
      if (last != null) {
        final diff = today.difference(_startOfDay(last)).inDays;
        if (diff == 0) {
          return LocalRow($id: userId, data: streak);
        } else if (diff == 1) {
          currentStreak += 1;
        } else {
          currentStreak = 1;
        }
      } else {
        currentStreak = 1;
      }
    } else {
      currentStreak = 1;
    }

    if (currentStreak > longestStreak) longestStreak = currentStreak;

    streak['currentStreak'] = currentStreak;
    streak['longestStreak'] = longestStreak;
    streak['lastCheckIn'] = now.toIso8601String();

    // Write to Appwrite
    try {
      await _db.updateDocument(
        databaseId: _dbId,
        collectionId: AppwriteConstants.streaksCollection,
        documentId: userId,
        data: {
          'currentStreak': currentStreak,
          'longestStreak': longestStreak,
          'lastCheckIn': now.toIso8601String(),
        },
      );
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        try {
          await _db.createDocument(
            databaseId: _dbId,
            collectionId: AppwriteConstants.streaksCollection,
            documentId: userId,
            data: streak,
            permissions: [
              Permission.read(Role.user(userId)),
              Permission.write(Role.user(userId)),
            ],
          );
        } catch (_) {}
      } else {
        developer.log('updateStreak remote failed: ${e.message}', name: _tag);
      }
    } catch (e) {
      developer.log('updateStreak remote failed', name: _tag, error: e);
    }

    await LocalDataService().saveStreak(userId, streak);
    return LocalRow($id: userId, data: streak);
  }

  // ──────────────────────────────────────────────
  // RECOVERY SCORES
  // ──────────────────────────────────────────────

  Future<LocalRow> saveRecoveryScore({
    required String userId,
    required double score,
    List<String>? factors,
  }) async {
    await _ensureUserId(userId);
    final data = <String, dynamic>{
      'userId': userId,
      'score': score.clamp(0.0, 100.0),
      'factors': factors ?? <String>[],
      'avgMood': null,
      'date': _dayKey(DateTime.now()),
    };

    // Write to Appwrite
    try {
      await _db.createDocument(
        databaseId: _dbId,
        collectionId: AppwriteConstants.recoveryScoresCollection,
        documentId: ID.unique(),
        data: data,
        permissions: [
          Permission.read(Role.user(userId)),
          Permission.write(Role.user(userId)),
        ],
      );
    } on AppwriteException catch (e) {
      developer.log('saveRecoveryScore remote failed: ${e.message}', name: _tag);
    } catch (e) {
      developer.log('saveRecoveryScore remote failed', name: _tag, error: e);
    }

    // Cache locally
    final history = LocalDataService().getRecoveryHistory(userId);
    history.add(data);
    await LocalDataService().saveRecoveryHistory(userId, history);
    return LocalRow($id: _newId('recovery'), data: data);
  }

  Future<double?> getLatestRecoveryScore(String userId) async {
    await _ensureUserId(userId);

    // Try Appwrite
    try {
      final result = await _db.listDocuments(
        databaseId: _dbId,
        collectionId: AppwriteConstants.recoveryScoresCollection,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('date'),
          Query.limit(1),
        ],
      );
      if (result.documents.isNotEmpty) {
        return (result.documents.first.data['score'] as num?)?.toDouble() ?? 100.0;
      }
    } on AppwriteException catch (e) {
      developer.log('getLatestRecoveryScore remote failed: ${e.message}', name: _tag);
    } catch (e) {
      developer.log('getLatestRecoveryScore remote failed', name: _tag, error: e);
    }

    // Fallback to local
    final history = LocalDataService().getRecoveryHistory(userId);
    if (history.isEmpty) return 100.0;
    history.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    return (history.last['score'] as num?)?.toDouble() ?? 100.0;
  }

  // ──────────────────────────────────────────────
  // COMMUNITY POSTS
  // ──────────────────────────────────────────────

  Future<LocalRow> createPost({
    required String userId,
    required String username,
    required String avatar,
    required String caption,
    String? imagePath,
    String? imageFileId,
    String? moodTag,
    String postType = 'All',
  }) async {
    await _ensureUserId(userId);
    final row = <String, dynamic>{
      'userId': userId,
      'username': username,
      'avatar': avatar,
      'imageFileId': imageFileId,
      'imagePath': imageFileId != null ? StorageService().getPostImageUrl(imageFileId) : null,
      'caption': caption,
      'moodTag': moodTag,
      'postType': postType,
      'likesCount': 0,
      'likedBy': <String>[],
      'timestamp': DateTime.now().toIso8601String(),
    };

    String docId = _newId('post');

    // Write to Appwrite — visible to all users
    try {
      final doc = await _db.createDocument(
        databaseId: _dbId,
        collectionId: AppwriteConstants.postsCollection,
        documentId: ID.unique(),
        data: row,
        permissions: [
          Permission.read(Role.users()),
          Permission.update(Role.users()),
          Permission.delete(Role.user(userId)),
        ],
      );
      docId = doc.$id;
    } on AppwriteException catch (e) {
      developer.log('createPost remote failed: ${e.message}', name: _tag);
    } catch (e) {
      developer.log('createPost remote failed', name: _tag, error: e);
    }

    // Cache locally
    row['id'] = docId;
    row['imagePath'] = imagePath;
    row['comments'] = <Map<String, dynamic>>[];
    final posts = LocalDataService().getCommunityPosts();
    posts.insert(0, row);
    await LocalDataService().saveCommunityPosts(posts);
    await LocalDataService().addAnalytics('community_post_created');
    return LocalRow($id: docId, data: row);
  }

  Future<LocalRowList> getPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    await LocalDataService().init();

    // Try Appwrite — returns ALL users' posts
    try {
      final result = await _db.listDocuments(
        databaseId: _dbId,
        collectionId: AppwriteConstants.postsCollection,
        queries: [
          Query.orderDesc('timestamp'),
          Query.limit(limit),
          Query.offset(offset),
        ],
      );

      if (result.documents.isNotEmpty) {
        final remotePosts = result.documents
            .map((doc) => <String, dynamic>{
                  ...doc.data,
                  'id': doc.$id,
                  'comments': <Map<String, dynamic>>[],
                })
            .toList();

        // Update local cache
        if (offset == 0) {
          final localPosts = LocalDataService().getCommunityPosts();
          final remoteIds = remotePosts.map((e) => e['id']).toSet();
          final merged = <Map<String, dynamic>>[
            ...remotePosts,
            ...localPosts.where((e) => !remoteIds.contains(e['id'])),
          ];
          merged.sort((a, b) =>
              (b['timestamp'] as String).compareTo(a['timestamp'] as String));
          await LocalDataService().saveCommunityPosts(merged);
        }

        return LocalRowList(
          rows: remotePosts
              .map((e) => LocalRow($id: e['id'] as String, data: e))
              .toList(),
        );
      }
    } on AppwriteException catch (e) {
      developer.log('getPosts remote failed: ${e.message}', name: _tag);
    } catch (e) {
      developer.log('getPosts remote failed', name: _tag, error: e);
    }

    // Fallback to local
    final posts = LocalDataService().getCommunityPosts();
    posts.sort((a, b) =>
        (b['timestamp'] as String).compareTo(a['timestamp'] as String));
    final sliced = posts.skip(offset).take(limit).toList();
    return LocalRowList(
      rows: sliced
          .map((e) => LocalRow($id: e['id'] as String, data: e))
          .toList(),
    );
  }

  Future<void> togglePostLike({
    required String postId,
    required String userId,
  }) async {
    await _ensureUserId(userId);

    // Update local first
    final posts = LocalDataService().getCommunityPosts();
    final idx = posts.indexWhere((p) => p['id'] == postId);
    if (idx == -1) return;
    final post = posts[idx];
    final likedBy = (post['likedBy'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();
    int likes = (post['likesCount'] as num?)?.toInt() ?? 0;
    if (likedBy.contains(userId)) {
      likedBy.remove(userId);
      likes = max(0, likes - 1);
    } else {
      likedBy.add(userId);
      likes += 1;
    }
    post['likedBy'] = likedBy;
    post['likesCount'] = likes;
    posts[idx] = post;
    await LocalDataService().saveCommunityPosts(posts);

    // Sync to Appwrite
    try {
      await _db.updateDocument(
        databaseId: _dbId,
        collectionId: AppwriteConstants.postsCollection,
        documentId: postId,
        data: {
          'likedBy': likedBy,
          'likesCount': likes,
        },
      );
    } on AppwriteException catch (e) {
      developer.log('togglePostLike remote failed: ${e.message}', name: _tag);
    } catch (e) {
      developer.log('togglePostLike remote failed', name: _tag, error: e);
    }
  }

  // ──────────────────────────────────────────────
  // COMMENTS (separate collection)
  // ──────────────────────────────────────────────

  Future<LocalRow> addComment({
    required String postId,
    required String userId,
    required String username,
    required String avatar,
    required String text,
  }) async {
    await _ensureUserId(userId);
    final row = <String, dynamic>{
      'postId': postId,
      'userId': userId,
      'username': username,
      'avatar': avatar,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    };

    String docId = _newId('comment');

    // Write to Appwrite comments collection
    try {
      final doc = await _db.createDocument(
        databaseId: _dbId,
        collectionId: AppwriteConstants.commentsCollection,
        documentId: ID.unique(),
        data: row,
        permissions: [
          Permission.read(Role.users()),
          Permission.delete(Role.user(userId)),
        ],
      );
      docId = doc.$id;
    } on AppwriteException catch (e) {
      developer.log('addComment remote failed: ${e.message}', name: _tag);
    } catch (e) {
      developer.log('addComment remote failed', name: _tag, error: e);
    }

    // Cache locally in post's comments
    row['id'] = docId;
    final posts = LocalDataService().getCommunityPosts();
    final idx = posts.indexWhere((p) => p['id'] == postId);
    if (idx != -1) {
      final post = posts[idx];
      final comments = (post['comments'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      comments.add(row);
      post['comments'] = comments;
      posts[idx] = post;
      await LocalDataService().saveCommunityPosts(posts);
    }

    return LocalRow($id: docId, data: row);
  }

  Future<LocalRowList> getComments(String postId) async {
    await LocalDataService().init();

    // Try Appwrite
    try {
      final result = await _db.listDocuments(
        databaseId: _dbId,
        collectionId: AppwriteConstants.commentsCollection,
        queries: [
          Query.equal('postId', postId),
          Query.orderAsc('timestamp'),
          Query.limit(100),
        ],
      );

      if (result.documents.isNotEmpty) {
        return LocalRowList(
          rows: result.documents
              .map((doc) => LocalRow(
                    $id: doc.$id,
                    data: <String, dynamic>{...doc.data, 'id': doc.$id},
                  ))
              .toList(),
        );
      }
    } on AppwriteException catch (e) {
      developer.log('getComments remote failed: ${e.message}', name: _tag);
    } catch (e) {
      developer.log('getComments remote failed', name: _tag, error: e);
    }

    // Fallback to local
    final posts = LocalDataService().getCommunityPosts();
    final post = posts.cast<Map<String, dynamic>?>().firstWhere(
      (p) => p?['id'] == postId,
      orElse: () => null,
    );
    if (post == null) return LocalRowList(rows: <LocalRow>[]);
    final comments = (post['comments'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    comments.sort((a, b) =>
        (a['timestamp'] as String).compareTo(b['timestamp'] as String));
    return LocalRowList(
      rows: comments
          .map((e) => LocalRow($id: e['id'] as String, data: e))
          .toList(),
    );
  }

  // ──────────────────────────────────────────────
  // SLEEP + DREAMS
  // ──────────────────────────────────────────────

  Future<void> saveSleepLog({
    required String userId,
    required double hours,
    required String dreamType,
    required String dreamDescription,
  }) async {
    await _ensureUserId(userId);
    final todayKey = _dayKey(DateTime.now());
    final data = <String, dynamic>{
      'userId': userId,
      'date': todayKey,
      'hours': hours,
      'dreamType': dreamType,
      'dreamDescription': dreamDescription,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Write to Appwrite (not a defined collection in constants, store locally)
    // Sleep logs stored locally for now — extend when collection is added

    final logs = LocalDataService().getSleepLogs(userId);
    logs.removeWhere((l) => (l['date'] as String?) == todayKey);
    data['id'] = _newId('sleep');
    logs.add(data);
    logs.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    await LocalDataService().saveSleepLogs(userId, logs);
    await LocalDataService().addAnalytics(
      'sleep_log_saved',
      payload: <String, dynamic>{
        'userId': userId,
        'hours': hours,
        'dreamType': dreamType,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getSleepLogs(
    String userId, {
    int days = 7,
  }) async {
    await _ensureUserId(userId);
    final logs = LocalDataService().getSleepLogs(userId);
    final map = <String, Map<String, dynamic>>{};
    for (final l in logs) {
      map[l['date'] as String] = l;
    }
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];
    for (int i = days - 1; i >= 0; i--) {
      final day = _startOfDay(now.subtract(Duration(days: i)));
      final key = _dayKey(day);
      final entry = map[key];
      result.add(<String, dynamic>{
        'date': key,
        'hours': (entry?['hours'] as num?)?.toDouble() ?? 0.0,
        'dreamType': entry?['dreamType'],
        'dreamDescription': entry?['dreamDescription'],
      });
    }
    return result;
  }

  // ──────────────────────────────────────────────
  // BREATHING
  // ──────────────────────────────────────────────

  Future<void> saveBreathingSession({
    required String userId,
    required int durationSeconds,
    required bool ambientEnabled,
  }) async {
    await _ensureUserId(userId);
    final logs = LocalDataService().getBreathingLogs(userId);
    logs.insert(0, <String, dynamic>{
      'id': _newId('breath'),
      'durationSeconds': durationSeconds,
      'ambientEnabled': ambientEnabled,
      'timestamp': DateTime.now().toIso8601String(),
    });
    if (logs.length > 500) {
      logs.removeRange(500, logs.length);
    }
    await LocalDataService().saveBreathingLogs(userId, logs);
    await LocalDataService().addAnalytics(
      'breathing_session_saved',
      payload: <String, dynamic>{
        'userId': userId,
        'durationSeconds': durationSeconds,
      },
    );
  }

  // ──────────────────────────────────────────────
  // MUSIC LISTENS
  // ──────────────────────────────────────────────

  Future<void> saveListenedSong({
    required String userId,
    required String title,
    required String artist,
    required String playlist,
    String? mood,
  }) async {
    await _ensureUserId(userId);
    final listens = LocalDataService().getListenedSongs(userId);
    listens.insert(0, <String, dynamic>{
      'id': _newId('listen'),
      'title': title,
      'artist': artist,
      'playlist': playlist,
      'mood': mood,
      'timestamp': DateTime.now().toIso8601String(),
    });
    if (listens.length > 500) {
      listens.removeRange(500, listens.length);
    }
    await LocalDataService().saveListenedSongs(userId, listens);
    await LocalDataService().addAnalytics(
      'song_listened',
      payload: <String, dynamic>{
        'userId': userId,
        'title': title,
        'artist': artist,
        'playlist': playlist,
      },
    );
  }
}
