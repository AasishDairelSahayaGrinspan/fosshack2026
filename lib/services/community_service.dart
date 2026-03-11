import '../models/community_models.dart';
import 'database_service.dart';
import 'auth_service.dart';
import 'storage_service.dart';

/// Community data service — backed by Appwrite.
/// Falls back to local sample data if not logged in.
class CommunityService {
  static final CommunityService _instance = CommunityService._();
  factory CommunityService() => _instance;
  CommunityService._();

  String communityPreference = 'yes';

  bool get canPost => communityPreference != 'no';

  final DatabaseService _db = DatabaseService();

  // ─── Local cache ───
  List<Post> _posts = [];
  List<Post> get posts => List.unmodifiable(_posts);

  /// Load posts from Appwrite.
  Future<void> loadPosts() async {
    try {
      final result = await _db.getPosts();
      _posts = result.rows.map((doc) {
        final d = doc.data;
        return Post(
          id: doc.$id,
          username: d['username'] ?? '',
          avatar: d['avatar'] ?? '',
          imagePath: d['imagePath'],
          caption: d['caption'] ?? '',
          moodTag: d['moodTag'],
          postType: d['postType'] ?? 'All',
          timestamp: DateTime.parse(d['timestamp']),
          likesCount: d['likesCount'] ?? 0,
          isLiked: _isLikedByCurrentUser(d['likedBy']),
        );
      }).toList();
    } catch (_) {
      // Keep existing cache on failure
    }
  }

  bool _isLikedByCurrentUser(dynamic likedBy) {
    final user = AuthService().currentUser;
    if (user == null || likedBy == null) return false;
    return (likedBy is List) && likedBy.contains(user.$id);
  }

  /// Load comments for a specific post from Appwrite.
  Future<List<Comment>> loadComments(String postId) async {
    try {
      final result = await _db.getComments(postId);
      return result.rows.map((doc) {
        final d = doc.data;
        return Comment(
          id: doc.$id,
          username: d['username'] ?? '',
          avatar: d['avatar'] ?? '',
          text: d['text'] ?? '',
          timestamp: DateTime.parse(d['timestamp']),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Initialize with sample posts for demo (unchanged for offline mode).
  void initSampleData() {
    if (_posts.isNotEmpty) return;

    int nextPostId = 1;
    int nextCommentId = 1;

    _posts.addAll([
      Post(
        id: '${nextPostId++}',
        username: 'gentle_soul',
        avatar: 'G',
        caption: 'Today I chose rest over guilt. It felt like a small revolution.',
        moodTag: 'Healing',
        postType: 'Victories',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        likesCount: 14,
      ),
      Post(
        id: '${nextPostId++}',
        username: 'quiet_river',
        avatar: 'Q',
        caption:
            'Three months sober. Not counting days to brag — counting them to remind myself I can do hard things.',
        moodTag: 'Progress',
        postType: 'Achievements',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        likesCount: 42,
        comments: [
          Comment(
            id: '${nextCommentId++}',
            username: 'warm_light',
            avatar: 'W',
            text: 'So proud of you. Keep going.',
            timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          ),
          Comment(
            id: '${nextCommentId++}',
            username: 'still_waters',
            avatar: 'S',
            text: 'You are stronger than you know.',
            timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 30)),
          ),
        ],
      ),
      Post(
        id: '${nextPostId++}',
        username: 'morning_dew',
        avatar: 'M',
        caption:
            'I sat with my sadness today instead of running from it. That felt like progress.',
        moodTag: 'Grateful',
        postType: 'Victories',
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        likesCount: 23,
      ),
      Post(
        id: '${nextPostId++}',
        username: 'soft_horizon',
        avatar: 'S',
        caption:
            'Went for a walk without my phone. The world felt quieter and kinder.',
        moodTag: 'Healing',
        postType: 'Heartbreak',
        timestamp: DateTime.now().subtract(const Duration(hours: 12)),
        likesCount: 31,
        comments: [
          Comment(
            id: '${nextCommentId++}',
            username: 'gentle_soul',
            avatar: 'G',
            text: 'This is beautiful. I need to try this.',
            timestamp: DateTime.now().subtract(const Duration(hours: 11)),
          ),
        ],
      ),
      Post(
        id: '${nextPostId++}',
        username: 'still_waters',
        avatar: 'S',
        caption:
            'Some days the bravest thing you do is simply get through it. Today was one of those days.',
        moodTag: 'Struggling',
        postType: 'Struggles',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        likesCount: 56,
      ),
    ]);
  }

  Future<void> addPost({
    required String caption,
    String? imagePath,
    String? moodTag,
  }) async {
    final user = AuthService().currentUser;
    if (user == null) {
      // Offline fallback
      _posts.insert(
        0,
        Post(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          username: 'you',
          avatar: 'Y',
          imagePath: imagePath,
          caption: caption,
          moodTag: moodTag,
          timestamp: DateTime.now(),
        ),
      );
      return;
    }

    // Upload image if provided
    String? uploadedImageId;
    if (imagePath != null) {
      final file = await StorageService().uploadPostImage(
        filePath: imagePath,
        fileName: 'post_${DateTime.now().millisecondsSinceEpoch}.jpg',
        userId: user.$id,
      );
      uploadedImageId = StorageService().getPostImageUrl(file.$id);
    }

    final doc = await _db.createPost(
      userId: user.$id,
      username: user.name.isNotEmpty ? user.name : 'you',
      avatar: user.name.isNotEmpty ? user.name[0].toUpperCase() : 'Y',
      caption: caption,
      imagePath: uploadedImageId,
      moodTag: moodTag,
    );

    _posts.insert(
      0,
      Post(
        id: doc.$id,
        username: user.name.isNotEmpty ? user.name : 'you',
        avatar: user.name.isNotEmpty ? user.name[0].toUpperCase() : 'Y',
        imagePath: uploadedImageId,
        caption: caption,
        moodTag: moodTag,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> toggleLike(String postId) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final post = _posts[idx];
    post.isLiked = !post.isLiked;
    post.likesCount += post.isLiked ? 1 : -1;

    final user = AuthService().currentUser;
    if (user != null) {
      try {
        await _db.togglePostLike(postId: postId, userId: user.$id);
      } catch (_) {
        // Revert on failure
        post.isLiked = !post.isLiked;
        post.likesCount += post.isLiked ? 1 : -1;
      }
    }
  }

  Future<void> addComment(String postId, String text) async {
    final user = AuthService().currentUser;
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final post = _posts[idx];

    final username = user?.name ?? 'you';
    final avatar = username.isNotEmpty ? username[0].toUpperCase() : 'Y';

    final comment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      avatar: avatar,
      text: text,
      timestamp: DateTime.now(),
    );
    post.comments.add(comment);

    if (user != null) {
      try {
        await _db.addComment(
          postId: postId,
          userId: user.$id,
          username: username,
          avatar: avatar,
          text: text,
        );
      } catch (_) {
        // Comment already added locally
      }
    }
  }

  String formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
