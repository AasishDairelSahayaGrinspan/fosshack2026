import '../models/community_models.dart';

/// Local in-memory community data service.
/// Will be replaced with backend integration later.
class CommunityService {
  static final CommunityService _instance = CommunityService._();
  factory CommunityService() => _instance;
  CommunityService._();

  // Community participation preference
  String communityPreference = 'yes'; // 'yes', 'browsing', 'no'

  bool get canPost => communityPreference != 'no';

  final List<Post> _posts = [];
  int _nextPostId = 1;
  int _nextCommentId = 1;

  List<Post> get posts => List.unmodifiable(_posts);

  /// Initialize with sample posts for demo.
  void initSampleData() {
    if (_posts.isNotEmpty) return;

    _posts.addAll([
      Post(
        id: '${_nextPostId++}',
        username: 'gentle_soul',
        avatar: 'G',
        caption:
            'Today I chose rest over guilt. It felt like a small revolution.',
        moodTag: 'Healing',
        postType: 'Victories',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        likesCount: 14,
      ),
      Post(
        id: '${_nextPostId++}',
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
            id: '${_nextCommentId++}',
            username: 'warm_light',
            avatar: 'W',
            text: 'So proud of you. Keep going.',
            timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          ),
          Comment(
            id: '${_nextCommentId++}',
            username: 'still_waters',
            avatar: 'S',
            text: 'You are stronger than you know.',
            timestamp:
                DateTime.now().subtract(const Duration(hours: 3, minutes: 30)),
          ),
        ],
      ),
      Post(
        id: '${_nextPostId++}',
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
        id: '${_nextPostId++}',
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
            id: '${_nextCommentId++}',
            username: 'gentle_soul',
            avatar: 'G',
            text: 'This is beautiful. I need to try this.',
            timestamp: DateTime.now().subtract(const Duration(hours: 11)),
          ),
        ],
      ),
      Post(
        id: '${_nextPostId++}',
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

  void addPost({
    required String caption,
    String? imagePath,
    String? moodTag,
  }) {
    _posts.insert(
      0,
      Post(
        id: '${_nextPostId++}',
        username: 'you',
        avatar: 'Y',
        imagePath: imagePath,
        caption: caption,
        moodTag: moodTag,
        timestamp: DateTime.now(),
      ),
    );
  }

  void toggleLike(String postId) {
    final post = _posts.firstWhere((p) => p.id == postId);
    post.isLiked = !post.isLiked;
    post.likesCount += post.isLiked ? 1 : -1;
  }

  void addComment(String postId, String text) {
    final post = _posts.firstWhere((p) => p.id == postId);
    post.comments.add(Comment(
      id: '${_nextCommentId++}',
      username: 'you',
      avatar: 'Y',
      text: text,
      timestamp: DateTime.now(),
    ));
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
