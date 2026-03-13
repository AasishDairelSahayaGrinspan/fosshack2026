import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'appwrite_service.dart';
import 'appwrite_constants.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final Databases _db = AppwriteService().databases;
  static const _dbId = AppwriteConstants.databaseId;

  // ═══════════════════════════════════════════════════
  //  USER PROFILE
  // ═══════════════════════════════════════════════════

  Future<models.Document> createUserProfile({
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
  }) async {
    return await _db.createDocument(
      databaseId: _dbId,
      collectionId: AppwriteConstants.usersCollection,
      documentId: userId,
      data: {
        'userId': userId,
        'name': name,
        'ageGroup': ageGroup,
        'concerns': concerns ?? [],
        'sleepSchedule': sleepSchedule,
        'moodBaseline': moodBaseline,
        'avatarUrl': avatarUrl,
        'hairStyle': hairStyle,
        'skinTone': skinTone,
        'outfitColor': outfitColor,
        'createdAt': DateTime.now().toIso8601String(),
      },
      permissions: [
        Permission.read(Role.user(userId)),
        Permission.update(Role.user(userId)),
        Permission.delete(Role.user(userId)),
      ],
    );
  }

  Future<models.Document> getUserProfile(String userId) async {
    return await _db.getDocument(
      databaseId: _dbId,
      collectionId: AppwriteConstants.usersCollection,
      documentId: userId,
    );
  }

  Future<models.Document> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    return await _db.updateDocument(
      databaseId: _dbId,
      collectionId: AppwriteConstants.usersCollection,
      documentId: userId,
      data: data,
    );
  }

  // ═══════════════════════════════════════════════════
  //  MOOD ENTRIES
  // ═══════════════════════════════════════════════════

  Future<models.Document> saveMoodEntry({
    required String userId,
    required double mood,
    required String emoji,
    String? note,
  }) async {
    return await _db.createDocument(
      databaseId: _dbId,
      collectionId: AppwriteConstants.moodEntriesCollection,
      documentId: ID.unique(),
      data: {
        'userId': userId,
        'mood': mood,
        'emoji': emoji,
        'note': note,
        'timestamp': DateTime.now().toIso8601String(),
      },
      permissions: [
        Permission.read(Role.user(userId)),
        Permission.delete(Role.user(userId)),
      ],
    );
  }

  /// Get last [days] mood entries for the weekly chart.
  Future<models.DocumentList> getMoodEntries(
    String userId, {
    int days = 7,
  }) async {
    final since = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String();

    return await _db.listDocuments(
      databaseId: _dbId,
      collectionId: AppwriteConstants.moodEntriesCollection,
      queries: [
        Query.equal('userId', userId),
        Query.greaterThanEqual('timestamp', since),
        Query.orderAsc('timestamp'),
        Query.limit(days),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  //  JOURNAL ENTRIES
  // ═══════════════════════════════════════════════════

  Future<models.Document> saveJournalEntry({
    required String userId,
    required String content,
    String? moodTag,
    String? prompt,
    List<String>? mediaIds,
  }) async {
    return await _db.createDocument(
      databaseId: _dbId,
      collectionId: AppwriteConstants.journalEntriesCollection,
      documentId: ID.unique(),
      data: {
        'userId': userId,
        'content': content,
        'moodTag': moodTag,
        'prompt': prompt,
        'mediaIds': mediaIds ?? [],
        'timestamp': DateTime.now().toIso8601String(),
      },
      permissions: [
        Permission.read(Role.user(userId)),
        Permission.update(Role.user(userId)),
        Permission.delete(Role.user(userId)),
      ],
    );
  }

  Future<models.DocumentList> getJournalEntries(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    return await _db.listDocuments(
      databaseId: _dbId,
      collectionId: AppwriteConstants.journalEntriesCollection,
      queries: [
        Query.equal('userId', userId),
        Query.orderDesc('timestamp'),
        Query.limit(limit),
        Query.offset(offset),
      ],
    );
  }

  Future<void> deleteJournalEntry(String documentId) async {
    await _db.deleteDocument(
      databaseId: _dbId,
      collectionId: AppwriteConstants.journalEntriesCollection,
      documentId: documentId,
    );
  }

  // ═══════════════════════════════════════════════════
  //  STREAKS
  // ═══════════════════════════════════════════════════

  Future<models.Document> getOrCreateStreak(String userId) async {
    try {
      return await _db.getDocument(
        databaseId: _dbId,
        collectionId: AppwriteConstants.streaksCollection,
        documentId: userId,
      );
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        try {
          return await _db.createDocument(
            databaseId: _dbId,
            collectionId: AppwriteConstants.streaksCollection,
            documentId: userId,
            data: {
              'userId': userId,
              'currentStreak': 0,
              'longestStreak': 0,
              'lastCheckIn': null,
            },
            permissions: [
              Permission.read(Role.user(userId)),
              Permission.update(Role.user(userId)),
            ],
          );
        } catch (_) {
          rethrow;
        }
      }
      rethrow;
    }
  }

  /// Call this when user completes a daily check-in.
  Future<models.Document> updateStreak(String userId) async {
    final doc = await getOrCreateStreak(userId);
    final data = doc.data;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int currentStreak = data['currentStreak'] ?? 0;
    int longestStreak = data['longestStreak'] ?? 0;

    if (data['lastCheckIn'] != null) {
      final lastCheckIn = DateTime.parse(data['lastCheckIn']);
      final lastDate = DateTime(
        lastCheckIn.year,
        lastCheckIn.month,
        lastCheckIn.day,
      );
      final diff = today.difference(lastDate).inDays;

      if (diff == 0) {
        // Already checked in today
        return doc;
      } else if (diff == 1) {
        currentStreak += 1;
      } else {
        // Streak broken
        currentStreak = 1;
      }
    } else {
      currentStreak = 1;
    }

    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }

    return await _db.updateDocument(
      databaseId: _dbId,
      collectionId: AppwriteConstants.streaksCollection,
      documentId: userId,
      data: {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastCheckIn': now.toIso8601String(),
      },
    );
  }

  // ═══════════════════════════════════════════════════
  //  RECOVERY SCORES
  // ═══════════════════════════════════════════════════

  Future<models.Document> saveRecoveryScore({
    required String userId,
    required double score,
    List<String>? factors,
  }) async {
    return await _db.createDocument(
      databaseId: _dbId,
      collectionId: AppwriteConstants.recoveryScoresCollection,
      documentId: ID.unique(),
      data: {
        'userId': userId,
        'score': score,
        'factors': factors ?? [],
        'date': DateTime.now().toIso8601String(),
      },
      permissions: [
        Permission.read(Role.user(userId)),
      ],
    );
  }

  Future<double?> getLatestRecoveryScore(String userId) async {
    final result = await _db.listDocuments(
      databaseId: _dbId,
      collectionId: AppwriteConstants.recoveryScoresCollection,
      queries: [
        Query.equal('userId', userId),
        Query.orderDesc('date'),
        Query.limit(1),
      ],
    );
    if (result.documents.isEmpty) return null;
    return (result.documents.first.data['score'] as num).toDouble();
  }

  // ═══════════════════════════════════════════════════
  //  SLEEP ENTRIES
  // ═══════════════════════════════════════════════════

  Future<models.Document> saveSleepEntry({
    required String userId,
    required double hours,
    required String date,
  }) async {
    return await _db.createDocument(
      databaseId: _dbId,
      collectionId: AppwriteConstants.sleepEntriesCollection,
      documentId: ID.unique(),
      data: {
        'userId': userId,
        'hours': hours,
        'date': date,
      },
      permissions: [
        Permission.read(Role.user(userId)),
        Permission.delete(Role.user(userId)),
      ],
    );
  }

  Future<models.DocumentList> getSleepEntries(
    String userId, {
    int days = 7,
  }) async {
    final since = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String()
        .split('T')
        .first;

    return await _db.listDocuments(
      databaseId: _dbId,
      collectionId: AppwriteConstants.sleepEntriesCollection,
      queries: [
        Query.equal('userId', userId),
        Query.greaterThanEqual('date', since),
        Query.orderAsc('date'),
        Query.limit(days),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  //  CHAT MESSAGES
  // ═══════════════════════════════════════════════════

  Future<models.Document> sendChatMessage({
    required String userId,
    required String username,
    required String avatar,
    required String text,
  }) async {
    return await _db.createDocument(
      databaseId: _dbId,
      collectionId: AppwriteConstants.chatMessagesCollection,
      documentId: ID.unique(),
      data: {
        'userId': userId,
        'username': username,
        'avatar': avatar,
        'text': text,
        'timestamp': DateTime.now().toIso8601String(),
      },
      permissions: [
        Permission.read(Role.any()),
        Permission.delete(Role.user(userId)),
      ],
    );
  }

  Future<models.DocumentList> getChatMessages({
    int limit = 50,
  }) async {
    return await _db.listDocuments(
      databaseId: _dbId,
      collectionId: AppwriteConstants.chatMessagesCollection,
      queries: [
        Query.orderDesc('timestamp'),
        Query.limit(limit),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  //  DAILY NEED
  // ═══════════════════════════════════════════════════

  Future<void> saveDailyNeed({
    required String userId,
    required String need,
  }) async {
    try {
      await _db.updateDocument(
        databaseId: _dbId,
        collectionId: AppwriteConstants.streaksCollection,
        documentId: userId,
        data: {'dailyNeed': need},
      );
    } catch (_) {
      // Streak document may not exist yet — silently ignore
    }
  }

  // ═══════════════════════════════════════════════════
  //  RECOVERY SCORE COMPUTATION
  // ═══════════════════════════════════════════════════

  /// Compute and save a recovery score combining:
  /// mood (30%), sleep (30%), streak (20%), baseline (20%).
  Future<double> computeAndSaveRecoveryScore(String userId) async {
    double moodScore = 0.5;
    double sleepScore = 0.5;
    double streakScore = 0.0;
    double baselineScore = 0.5;

    // Mood: average of last 7 days (0..1)
    try {
      final moods = await getMoodEntries(userId, days: 7);
      if (moods.documents.isNotEmpty) {
        final values = moods.documents
            .map((d) => (d.data['mood'] as num).toDouble())
            .toList();
        moodScore = values.reduce((a, b) => a + b) / values.length;
      }
    } catch (_) {}

    // Sleep: average hours / 8 clamped to 0..1
    try {
      final sleeps = await getSleepEntries(userId, days: 7);
      if (sleeps.documents.isNotEmpty) {
        final values = sleeps.documents
            .map((d) => (d.data['hours'] as num).toDouble())
            .toList();
        final avg = values.reduce((a, b) => a + b) / values.length;
        sleepScore = (avg / 8.0).clamp(0.0, 1.0);
      }
    } catch (_) {}

    // Streak: currentStreak / 30 clamped to 0..1
    try {
      final streak = await getOrCreateStreak(userId);
      final current = (streak.data['currentStreak'] as num?) ?? 0;
      streakScore = (current / 30.0).clamp(0.0, 1.0);
    } catch (_) {}

    // Baseline from user preferences
    try {
      final profile = await getUserProfile(userId);
      baselineScore = (profile.data['moodBaseline'] as num?)?.toDouble() ?? 0.5;
    } catch (_) {}

    final score =
        moodScore * 0.30 + sleepScore * 0.30 + streakScore * 0.20 + baselineScore * 0.20;

    // Save the computed score
    try {
      await saveRecoveryScore(
        userId: userId,
        score: score,
        factors: ['mood:$moodScore', 'sleep:$sleepScore', 'streak:$streakScore', 'baseline:$baselineScore'],
      );
    } catch (_) {}

    return score;
  }

  // ═══════════════════════════════════════════════════
  //  COMMUNITY POSTS
  // ═══════════════════════════════════════════════════

  Future<models.Document> createPost({
    required String userId,
    required String username,
    required String avatar,
    required String caption,
    String? imagePath,
    String? moodTag,
    String postType = 'All',
  }) async {
    return await _db.createDocument(
      databaseId: _dbId,
      collectionId: AppwriteConstants.postsCollection,
      documentId: ID.unique(),
      data: {
        'userId': userId,
        'username': username,
        'avatar': avatar,
        'caption': caption,
        'imagePath': imagePath,
        'moodTag': moodTag,
        'postType': postType,
        'likesCount': 0,
        'likedBy': [],
        'timestamp': DateTime.now().toIso8601String(),
      },
      permissions: [
        Permission.read(Role.any()),
        Permission.update(Role.user(userId)),
        Permission.delete(Role.user(userId)),
      ],
    );
  }

  Future<models.DocumentList> getPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    return await _db.listDocuments(
      databaseId: _dbId,
      collectionId: AppwriteConstants.postsCollection,
      queries: [
        Query.orderDesc('timestamp'),
        Query.limit(limit),
        Query.offset(offset),
      ],
    );
  }

  Future<void> togglePostLike({
    required String postId,
    required String userId,
  }) async {
    final doc = await _db.getDocument(
      databaseId: _dbId,
      collectionId: AppwriteConstants.postsCollection,
      documentId: postId,
    );
    final List<dynamic> likedBy = List.from(doc.data['likedBy'] ?? []);
    int likesCount = doc.data['likesCount'] ?? 0;

    if (likedBy.contains(userId)) {
      likedBy.remove(userId);
      likesCount = (likesCount - 1).clamp(0, likesCount);
    } else {
      likedBy.add(userId);
      likesCount += 1;
    }

    await _db.updateDocument(
      databaseId: _dbId,
      collectionId: AppwriteConstants.postsCollection,
      documentId: postId,
      data: {
        'likedBy': likedBy,
        'likesCount': likesCount,
      },
    );
  }

  // ─── Comments ───

  Future<models.Document> addComment({
    required String postId,
    required String userId,
    required String username,
    required String avatar,
    required String text,
  }) async {
    return await _db.createDocument(
      databaseId: _dbId,
      collectionId: AppwriteConstants.commentsCollection,
      documentId: ID.unique(),
      data: {
        'postId': postId,
        'userId': userId,
        'username': username,
        'avatar': avatar,
        'text': text,
        'timestamp': DateTime.now().toIso8601String(),
      },
      permissions: [
        Permission.read(Role.any()),
        Permission.delete(Role.user(userId)),
      ],
    );
  }

  Future<models.DocumentList> getComments(String postId) async {
    return await _db.listDocuments(
      databaseId: _dbId,
      collectionId: AppwriteConstants.commentsCollection,
      queries: [
        Query.equal('postId', postId),
        Query.orderAsc('timestamp'),
        Query.limit(100),
      ],
    );
  }
}
