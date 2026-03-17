import 'dart:math';

import 'auth_service.dart';
import 'local_data_service.dart';

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

  Future<String> _ensureUserId(String userId) async {
    await LocalDataService().init();
    return userId;
  }

  String _newId([String prefix = 'id']) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}';

  String _dayKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  DateTime _startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // USER PROFILE
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
    await LocalDataService().saveUserPrefs(userId, data);
    return LocalRow($id: userId, data: data);
  }

  Future<LocalRow> getUserProfile(String userId) async {
    await _ensureUserId(userId);
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
    await LocalDataService().saveUserPrefs(userId, existing);
    return LocalRow($id: userId, data: existing);
  }

  // MOOD ENTRIES + RECOVERY
  Future<LocalRow> saveMoodEntry({
    required String userId,
    required double mood,
    required String emoji,
    String? note,
  }) async {
    await _ensureUserId(userId);
    final entries = LocalDataService().getMoodEntries(userId);
    final row = <String, dynamic>{
      'id': _newId('mood'),
      'userId': userId,
      'mood': mood,
      'emoji': emoji,
      'note': note,
      'timestamp': DateTime.now().toIso8601String(),
    };
    entries.add(row);
    entries.sort((a, b) => (a['timestamp'] as String).compareTo(b['timestamp'] as String));
    await LocalDataService().saveMoodEntries(userId, entries);
    await _recomputeRecoveryFromMood(userId);
    await LocalDataService().addAnalytics(
      'mood_saved',
      payload: <String, dynamic>{'userId': userId, 'mood': mood},
    );
    return LocalRow($id: row['id'] as String, data: row);
  }

  Future<LocalRowList> getMoodEntries(
    String userId, {
    int days = 7,
  }) async {
    await _ensureUserId(userId);
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
    final byDay = <String, List<double>>{};
    for (final entry in entries) {
      final ts = DateTime.tryParse((entry['timestamp'] as String?) ?? '');
      if (ts == null) continue;
      final key = _dayKey(ts);
      byDay.putIfAbsent(key, () => <double>[]);
      byDay[key]!.add((entry['mood'] as num).toDouble());
    }
    final keys = byDay.keys.toList()..sort();
    double score = 100.0;
    final history = <Map<String, dynamic>>[];
    for (final key in keys) {
      final values = byDay[key]!;
      final avg = values.reduce((a, b) => a + b) / values.length;
      final delta = (avg - 0.5) * 18.0;
      score = (score + delta).clamp(0.0, 100.0);
      history.add(<String, dynamic>{
        'date': key,
        'score': double.parse(score.toStringAsFixed(2)),
        'avgMood': double.parse(avg.toStringAsFixed(3)),
      });
    }
    if (history.isEmpty) {
      history.add(<String, dynamic>{
        'date': _dayKey(DateTime.now()),
        'score': 100.0,
        'avgMood': 0.5,
      });
    }
    await LocalDataService().saveRecoveryHistory(userId, history);
  }

  // JOURNAL
  Future<LocalRow> saveJournalEntry({
    required String userId,
    required String content,
    String? moodTag,
    String? prompt,
    List<String>? mediaIds,
  }) async {
    await _ensureUserId(userId);
    final entries = LocalDataService().getJournalEntries(userId);
    final row = <String, dynamic>{
      'id': _newId('journal'),
      'userId': userId,
      'content': content,
      'moodTag': moodTag,
      'prompt': prompt,
      'mediaIds': mediaIds ?? <String>[],
      'timestamp': DateTime.now().toIso8601String(),
    };
    entries.insert(0, row);
    await LocalDataService().saveJournalEntries(userId, entries);
    await LocalDataService().addAnalytics(
      'journal_saved',
      payload: <String, dynamic>{'userId': userId},
    );
    return LocalRow($id: row['id'] as String, data: row);
  }

  Future<LocalRowList> getJournalEntries(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    await _ensureUserId(userId);
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
    final entries = LocalDataService().getJournalEntries(user.$id);
    entries.removeWhere((e) => e['id'] == rowId);
    await LocalDataService().saveJournalEntries(user.$id, entries);
  }

  // STREAK
  Future<LocalRow> getOrCreateStreak(String userId) async {
    await _ensureUserId(userId);
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
    await LocalDataService().saveStreak(userId, streak);
    return LocalRow($id: userId, data: streak);
  }

  // RECOVERY SCORES
  Future<LocalRow> saveRecoveryScore({
    required String userId,
    required double score,
    List<String>? factors,
  }) async {
    await _ensureUserId(userId);
    final history = LocalDataService().getRecoveryHistory(userId);
    history.add(<String, dynamic>{
      'date': _dayKey(DateTime.now()),
      'score': score.clamp(0.0, 100.0),
      'factors': factors ?? <String>[],
      'avgMood': null,
    });
    await LocalDataService().saveRecoveryHistory(userId, history);
    return LocalRow(
      $id: _newId('recovery'),
      data: history.last,
    );
  }

  Future<double?> getLatestRecoveryScore(String userId) async {
    await _ensureUserId(userId);
    final history = LocalDataService().getRecoveryHistory(userId);
    if (history.isEmpty) return 100.0;
    history.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    return (history.last['score'] as num?)?.toDouble() ?? 100.0;
  }

  // COMMUNITY POSTS
  Future<LocalRow> createPost({
    required String userId,
    required String username,
    required String avatar,
    required String caption,
    String? imagePath,
    String? moodTag,
    String postType = 'All',
  }) async {
    await _ensureUserId(userId);
    final posts = LocalDataService().getCommunityPosts();
    final row = <String, dynamic>{
      'id': _newId('post'),
      'userId': userId,
      'username': username,
      'avatar': avatar,
      'imagePath': imagePath,
      'caption': caption,
      'moodTag': moodTag,
      'postType': postType,
      'likesCount': 0,
      'likedBy': <String>[],
      'comments': <Map<String, dynamic>>[],
      'timestamp': DateTime.now().toIso8601String(),
    };
    posts.insert(0, row);
    await LocalDataService().saveCommunityPosts(posts);
    await LocalDataService().addAnalytics('community_post_created');
    return LocalRow($id: row['id'] as String, data: row);
  }

  Future<LocalRowList> getPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    await LocalDataService().init();
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
  }

  // COMMENTS
  Future<LocalRow> addComment({
    required String postId,
    required String userId,
    required String username,
    required String avatar,
    required String text,
  }) async {
    await _ensureUserId(userId);
    final posts = LocalDataService().getCommunityPosts();
    final idx = posts.indexWhere((p) => p['id'] == postId);
    if (idx == -1) throw Exception('Post not found');
    final post = posts[idx];
    final comments = (post['comments'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final row = <String, dynamic>{
      'id': _newId('comment'),
      'postId': postId,
      'userId': userId,
      'username': username,
      'avatar': avatar,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    };
    comments.add(row);
    post['comments'] = comments;
    posts[idx] = post;
    await LocalDataService().saveCommunityPosts(posts);
    return LocalRow($id: row['id'] as String, data: row);
  }

  Future<LocalRowList> getComments(String postId) async {
    await LocalDataService().init();
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

  // SLEEP + DREAMS
  Future<void> saveSleepLog({
    required String userId,
    required double hours,
    required String dreamType,
    required String dreamDescription,
  }) async {
    await _ensureUserId(userId);
    final logs = LocalDataService().getSleepLogs(userId);
    final todayKey = _dayKey(DateTime.now());
    logs.removeWhere((l) => (l['date'] as String?) == todayKey);
    logs.add(<String, dynamic>{
      'id': _newId('sleep'),
      'date': todayKey,
      'hours': hours,
      'dreamType': dreamType,
      'dreamDescription': dreamDescription,
      'timestamp': DateTime.now().toIso8601String(),
    });
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

  // BREATHING
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

  // MUSIC LISTENS
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

