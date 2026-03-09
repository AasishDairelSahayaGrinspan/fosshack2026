// Community data models for Unravel.

class Comment {
  final String id;
  final String username;
  final String avatar;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.username,
    required this.avatar,
    required this.text,
    required this.timestamp,
  });
}

class Post {
  final String id;
  final String username;
  final String avatar;
  final String? imagePath;
  final String caption;
  final String? moodTag;
  final String postType; // 'Achievements', 'Heartbreak', 'Struggles', 'Victories'
  final DateTime timestamp;
  int likesCount;
  bool isLiked;
  final List<Comment> comments;

  Post({
    required this.id,
    required this.username,
    required this.avatar,
    this.imagePath,
    required this.caption,
    this.moodTag,
    this.postType = 'All',
    required this.timestamp,
    this.likesCount = 0,
    this.isLiked = false,
    List<Comment>? comments,
  }) : comments = comments ?? [];
}
