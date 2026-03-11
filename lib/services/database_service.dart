import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'appwrite_service.dart';
import 'appwrite_constants.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final TablesDB _db = AppwriteService().tablesDb;
  static const _dbId = AppwriteConstants.databaseId;

  // ═══════════════════════════════════════════════════
  //  USER PROFILE
  // ═══════════════════════════════════════════════════

  Future<models.Row> createUserProfile({
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
    return await _db.createRow(
      databaseId: _dbId,
      tableId: AppwriteConstants.usersCollection,
      rowId: userId,
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

  Future<models.Row> getUserProfile(String userId) async {
    return await _db.getRow(
      databaseId: _dbId,
      tableId: AppwriteConstants.usersCollection,
      rowId: userId,
    );
  }

  Future<models.Row> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    return await _db.updateRow(
      databaseId: _dbId,
      tableId: AppwriteConstants.usersCollection,
      rowId: userId,
      data: data,
    );
  }

  // ═══════════════════════════════════════════════════
  //  MOOD ENTRIES
  // ═══════════════════════════════════════════════════

  Future<models.Row> saveMoodEntry({
    required String userId,
    required double mood,
    required String emoji,
    String? note,
  }) async {
    return await _db.createRow(
      databaseId: _dbId,
      tableId: AppwriteConstants.moodEntriesCollection,
      rowId: ID.unique(),
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
  Future<models.RowList> getMoodEntries(
    String userId, {
    int days = 7,
  }) async {
    final since = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String();

    return await _db.listRows(
      databaseId: _dbId,
      tableId: AppwriteConstants.moodEntriesCollection,
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

  Future<models.Row> saveJournalEntry({
    required String userId,
    required String content,
    String? moodTag,
    String? prompt,
    List<String>? mediaIds,
  }) async {
    return await _db.createRow(
      databaseId: _dbId,
      tableId: AppwriteConstants.journalEntriesCollection,
      rowId: ID.unique(),
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

  Future<models.RowList> getJournalEntries(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    return await _db.listRows(
      databaseId: _dbId,
      tableId: AppwriteConstants.journalEntriesCollection,
      queries: [
        Query.equal('userId', userId),
        Query.orderDesc('timestamp'),
        Query.limit(limit),
        Query.offset(offset),
      ],
    );
  }

  Future<void> deleteJournalEntry(String rowId) async {
    await _db.deleteRow(
      databaseId: _dbId,
      tableId: AppwriteConstants.journalEntriesCollection,
      rowId: rowId,
    );
  }

  // ═══════════════════════════════════════════════════
  //  STREAKS
  // ═══════════════════════════════════════════════════

  Future<models.Row> getOrCreateStreak(String userId) async {
    try {
      return await _db.getRow(
        databaseId: _dbId,
        tableId: AppwriteConstants.streaksCollection,
        rowId: userId,
      );
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        return await _db.createRow(
          databaseId: _dbId,
          tableId: AppwriteConstants.streaksCollection,
          rowId: userId,
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
      }
      rethrow;
    }
  }

  /// Call this when user completes a daily check-in.
  Future<models.Row> updateStreak(String userId) async {
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

    return await _db.updateRow(
      databaseId: _dbId,
      tableId: AppwriteConstants.streaksCollection,
      rowId: userId,
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

  Future<models.Row> saveRecoveryScore({
    required String userId,
    required double score,
    List<String>? factors,
  }) async {
    return await _db.createRow(
      databaseId: _dbId,
      tableId: AppwriteConstants.recoveryScoresCollection,
      rowId: ID.unique(),
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
    final result = await _db.listRows(
      databaseId: _dbId,
      tableId: AppwriteConstants.recoveryScoresCollection,
      queries: [
        Query.equal('userId', userId),
        Query.orderDesc('date'),
        Query.limit(1),
      ],
    );
    if (result.rows.isEmpty) return null;
    return (result.rows.first.data['score'] as num).toDouble();
  }

  // ═══════════════════════════════════════════════════
  //  COMMUNITY POSTS
  // ═══════════════════════════════════════════════════

  Future<models.Row> createPost({
    required String userId,
    required String username,
    required String avatar,
    required String caption,
    String? imagePath,
    String? moodTag,
    String postType = 'All',
  }) async {
    return await _db.createRow(
      databaseId: _dbId,
      tableId: AppwriteConstants.postsCollection,
      rowId: ID.unique(),
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

  Future<models.RowList> getPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    return await _db.listRows(
      databaseId: _dbId,
      tableId: AppwriteConstants.postsCollection,
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
    final doc = await _db.getRow(
      databaseId: _dbId,
      tableId: AppwriteConstants.postsCollection,
      rowId: postId,
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

    await _db.updateRow(
      databaseId: _dbId,
      tableId: AppwriteConstants.postsCollection,
      rowId: postId,
      data: {
        'likedBy': likedBy,
        'likesCount': likesCount,
      },
    );
  }

  // ─── Comments ───

  Future<models.Row> addComment({
    required String postId,
    required String userId,
    required String username,
    required String avatar,
    required String text,
  }) async {
    return await _db.createRow(
      databaseId: _dbId,
      tableId: AppwriteConstants.commentsCollection,
      rowId: ID.unique(),
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

  Future<models.RowList> getComments(String postId) async {
    return await _db.listRows(
      databaseId: _dbId,
      tableId: AppwriteConstants.commentsCollection,
      queries: [
        Query.equal('postId', postId),
        Query.orderAsc('timestamp'),
        Query.limit(100),
      ],
    );
  }
}
