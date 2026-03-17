import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-first app backend with in-memory cache + SharedPreferences persistence.
class LocalDataService {
  LocalDataService._();
  static final LocalDataService _instance = LocalDataService._();
  factory LocalDataService() => _instance;

  static const String _tag = 'LocalDataService';
  static const String _rootKey = 'unravel_local_backend_v1';

  final ValueNotifier<bool> ready = ValueNotifier<bool>(false);
  Map<String, dynamic> _root = <String, dynamic>{};
  SharedPreferences? _prefs;

  Future<void> init() async {
    if (ready.value) return;
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e, st) {
      developer.log(
        'SharedPreferences init failed — running with in-memory only',
        name: _tag,
        error: e,
        stackTrace: st,
      );
    }
    final raw = _prefs?.getString(_rootKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        _root = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (e, st) {
        developer.log(
          'Corrupted local data — resetting to empty state',
          name: _tag,
          error: e,
          stackTrace: st,
        );
        _root = <String, dynamic>{};
      }
    }
    _root.putIfAbsent('session', () => <String, dynamic>{});
    _root.putIfAbsent('users', () => <String, dynamic>{});
    _root.putIfAbsent('userPrefs', () => <String, dynamic>{});
    _root.putIfAbsent('moods', () => <String, dynamic>{});
    _root.putIfAbsent('recoveryHistory', () => <String, dynamic>{});
    _root.putIfAbsent('journal', () => <String, dynamic>{});
    _root.putIfAbsent('streaks', () => <String, dynamic>{});
    _root.putIfAbsent('sleepLogs', () => <String, dynamic>{});
    _root.putIfAbsent('breathingLogs', () => <String, dynamic>{});
    _root.putIfAbsent('listenedSongs', () => <String, dynamic>{});
    _root.putIfAbsent('communityPosts', () => <dynamic>[]);
    _root.putIfAbsent('analytics', () => <dynamic>[]);
    ready.value = true;
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_rootKey, jsonEncode(_root));
    } catch (e, st) {
      developer.log(
        'Failed to persist data to SharedPreferences',
        name: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  Map<String, dynamic> _bucketMap(String key) {
    final existing = _root[key];
    if (existing is Map<String, dynamic>) return existing;
    final map = <String, dynamic>{};
    _root[key] = map;
    return map;
  }

  List<dynamic> _bucketList(String key) {
    final existing = _root[key];
    if (existing is List<dynamic>) return existing;
    final list = <dynamic>[];
    _root[key] = list;
    return list;
  }

  String? getSessionUserId() {
    final session = _bucketMap('session');
    return session['userId'] as String?;
  }

  Future<void> setSessionUserId(String? userId) async {
    final session = _bucketMap('session');
    if (userId == null) {
      session.remove('userId');
    } else {
      session['userId'] = userId;
    }
    await _persist();
  }

  Map<String, dynamic>? getUser(String userId) {
    final users = _bucketMap('users');
    final data = users[userId];
    if (data is Map<String, dynamic>) return Map<String, dynamic>.from(data);
    return null;
  }

  Future<void> saveUser(String userId, Map<String, dynamic> data) async {
    final users = _bucketMap('users');
    users[userId] = Map<String, dynamic>.from(data);
    await _persist();
  }

  Map<String, dynamic> getUserPrefs(String userId) {
    final prefs = _bucketMap('userPrefs');
    final raw = prefs[userId];
    if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  Future<void> saveUserPrefs(String userId, Map<String, dynamic> data) async {
    final prefs = _bucketMap('userPrefs');
    prefs[userId] = Map<String, dynamic>.from(data);
    await _persist();
  }

  List<Map<String, dynamic>> getMoodEntries(String userId) {
    final moods = _bucketMap('moods');
    final raw = moods[userId];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> saveMoodEntries(
    String userId,
    List<Map<String, dynamic>> entries,
  ) async {
    final moods = _bucketMap('moods');
    moods[userId] = entries;
    await _persist();
  }

  List<Map<String, dynamic>> getRecoveryHistory(String userId) {
    final historyBucket = _bucketMap('recoveryHistory');
    final raw = historyBucket[userId];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> saveRecoveryHistory(
    String userId,
    List<Map<String, dynamic>> history,
  ) async {
    final historyBucket = _bucketMap('recoveryHistory');
    historyBucket[userId] = history;
    await _persist();
  }

  List<Map<String, dynamic>> getJournalEntries(String userId) {
    final bucket = _bucketMap('journal');
    final raw = bucket[userId];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> saveJournalEntries(
    String userId,
    List<Map<String, dynamic>> entries,
  ) async {
    final bucket = _bucketMap('journal');
    bucket[userId] = entries;
    await _persist();
  }

  Map<String, dynamic> getStreak(String userId) {
    final bucket = _bucketMap('streaks');
    final raw = bucket[userId];
    if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{
      'userId': userId,
      'currentStreak': 0,
      'longestStreak': 0,
      'lastCheckIn': null,
    };
  }

  Future<void> saveStreak(String userId, Map<String, dynamic> streak) async {
    final bucket = _bucketMap('streaks');
    bucket[userId] = streak;
    await _persist();
  }

  List<Map<String, dynamic>> getSleepLogs(String userId) {
    final bucket = _bucketMap('sleepLogs');
    final raw = bucket[userId];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> saveSleepLogs(
    String userId,
    List<Map<String, dynamic>> logs,
  ) async {
    final bucket = _bucketMap('sleepLogs');
    bucket[userId] = logs;
    await _persist();
  }

  List<Map<String, dynamic>> getBreathingLogs(String userId) {
    final bucket = _bucketMap('breathingLogs');
    final raw = bucket[userId];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> saveBreathingLogs(
    String userId,
    List<Map<String, dynamic>> logs,
  ) async {
    final bucket = _bucketMap('breathingLogs');
    bucket[userId] = logs;
    await _persist();
  }

  List<Map<String, dynamic>> getListenedSongs(String userId) {
    final bucket = _bucketMap('listenedSongs');
    final raw = bucket[userId];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> saveListenedSongs(
    String userId,
    List<Map<String, dynamic>> songs,
  ) async {
    final bucket = _bucketMap('listenedSongs');
    bucket[userId] = songs;
    await _persist();
  }

  List<Map<String, dynamic>> getCommunityPosts() {
    final list = _bucketList('communityPosts');
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> saveCommunityPosts(List<Map<String, dynamic>> posts) async {
    _root['communityPosts'] = posts;
    await _persist();
  }

  Future<void> addAnalytics(
    String event, {
    Map<String, dynamic>? payload,
  }) async {
    final analytics = _bucketList('analytics');
    analytics.insert(0, <String, dynamic>{
      'event': event,
      'payload': payload ?? <String, dynamic>{},
      'timestamp': DateTime.now().toIso8601String(),
    });
    if (analytics.length > 500) {
      analytics.removeRange(500, analytics.length);
    }
    await _persist();
  }
}
