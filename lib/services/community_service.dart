import '../models/community_models.dart';
import 'auth_service.dart';
import 'database_service.dart';

/// Community data service - local backend, cached in memory.
class CommunityService {
  static final CommunityService _instance = CommunityService._();
  factory CommunityService() => _instance;
  CommunityService._();

  String communityPreference = 'yes';

  bool get canPost => communityPreference != 'no';

  final DatabaseService _db = DatabaseService();
  List<Post> _posts = <Post>[];
  List<Post> get posts => List<Post>.unmodifiable(_posts);

  Future<void> loadPosts() async {
    final result = await _db.getPosts(limit: 200, offset: 0);
    _posts = result.rows.map((doc) {
      final d = doc.data;
      final commentsData = (d['comments'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      return Post(
        id: doc.$id,
        username: (d['username'] as String?) ?? '',
        avatar: (d['avatar'] as String?) ?? '',
        imagePath: d['imagePath'] as String?,
        caption: (d['caption'] as String?) ?? '',
        moodTag: d['moodTag'] as String?,
        postType: (d['postType'] as String?) ?? 'All',
        timestamp: DateTime.tryParse((d['timestamp'] as String?) ?? '') ??
            DateTime.now(),
        likesCount: (d['likesCount'] as num?)?.toInt() ?? 0,
        isLiked: _isLikedByCurrentUser(d['likedBy']),
        comments: commentsData
            .map(
              (c) => Comment(
                id: (c['id'] as String?) ?? '',
                username: (c['username'] as String?) ?? '',
                avatar: (c['avatar'] as String?) ?? '',
                text: (c['text'] as String?) ?? '',
                timestamp:
                    DateTime.tryParse((c['timestamp'] as String?) ?? '') ??
                        DateTime.now(),
              ),
            )
            .toList(),
      );
    }).toList();
  }

  bool _isLikedByCurrentUser(dynamic likedBy) {
    final user = AuthService().currentUser;
    if (user == null || likedBy == null) return false;
    return (likedBy is List) && likedBy.contains(user.$id);
  }

  Future<List<Comment>> loadComments(String postId) async {
    final result = await _db.getComments(postId);
    return result.rows.map((doc) {
      final d = doc.data;
      return Comment(
        id: doc.$id,
        username: (d['username'] as String?) ?? '',
        avatar: (d['avatar'] as String?) ?? '',
        text: (d['text'] as String?) ?? '',
        timestamp:
            DateTime.tryParse((d['timestamp'] as String?) ?? '') ??
                DateTime.now(),
      );
    }).toList();
  }

  void initSampleData() {
    // Disabled by requirement: no mock data.
  }

  Future<void> addPost({
    required String caption,
    String? imagePath,
    String? moodTag,
  }) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final doc = await _db.createPost(
      userId: user.$id,
      username: user.name.isNotEmpty ? user.name : 'you',
      avatar: user.name.isNotEmpty ? user.name[0].toUpperCase() : 'Y',
      caption: caption,
      imagePath: imagePath,
      moodTag: moodTag,
    );

    _posts.insert(
      0,
      Post(
        id: doc.$id,
        username: user.name.isNotEmpty ? user.name : 'you',
        avatar: user.name.isNotEmpty ? user.name[0].toUpperCase() : 'Y',
        imagePath: imagePath,
        caption: caption,
        moodTag: moodTag,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> toggleLike(String postId) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final user = AuthService().currentUser;
    if (user == null) return;

    final post = _posts[idx];
    post.isLiked = !post.isLiked;
    post.likesCount += post.isLiked ? 1 : -1;
    await _db.togglePostLike(postId: postId, userId: user.$id);
  }

  Future<void> addComment(String postId, String text) async {
    final user = AuthService().currentUser;
    if (user == null) return;
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final post = _posts[idx];

    final username = user.name.isNotEmpty ? user.name : 'you';
    final avatar = username.isNotEmpty ? username[0].toUpperCase() : 'Y';
    await _db.addComment(
      postId: postId,
      userId: user.$id,
      username: username,
      avatar: avatar,
      text: text,
    );
    post.comments.add(
      Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username,
        avatar: avatar,
        text: text,
        timestamp: DateTime.now(),
      ),
    );
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

