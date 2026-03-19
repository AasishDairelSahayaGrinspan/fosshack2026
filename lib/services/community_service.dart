import 'dart:developer' as developer;

import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';

import '../models/community_models.dart';
import 'appwrite_constants.dart';
import 'appwrite_service.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';

/// Community data service — Appwrite-backed with realtime subscriptions.
class CommunityService extends ChangeNotifier {
  static final CommunityService _instance = CommunityService._();
  factory CommunityService() => _instance;
  CommunityService._();

  static const String _tag = 'CommunityService';

  String communityPreference = 'yes';
  bool get canPost => communityPreference == 'yes';

  final DatabaseService _db = DatabaseService();
  List<Post> _posts = <Post>[];
  List<Post> get posts => List<Post>.unmodifiable(_posts);

  RealtimeSubscription? _postsSubscription;
  RealtimeSubscription? _commentsSubscription;

  /// Subscribe to realtime events for posts and comments.
  void subscribeToRealtime() {
    try {
      final realtime = AppwriteService().realtime;

      // Subscribe to posts collection
      _postsSubscription = realtime.subscribe([
        'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.postsCollection}.documents',
      ]);

      _postsSubscription!.stream.listen(
        (event) {
          developer.log('Realtime post event: ${event.events}', name: _tag);
          // Reload posts on any change
          loadPosts();
        },
        onError: (error) {
          developer.log('Realtime posts error', name: _tag, error: error);
        },
      );

      // Subscribe to comments collection
      _commentsSubscription = realtime.subscribe([
        'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.commentsCollection}.documents',
      ]);

      _commentsSubscription!.stream.listen(
        (event) {
          developer.log('Realtime comment event: ${event.events}', name: _tag);
          notifyListeners();
        },
        onError: (error) {
          developer.log('Realtime comments error', name: _tag, error: error);
        },
      );
    } catch (e) {
      developer.log('subscribeToRealtime failed', name: _tag, error: e);
    }
  }

  /// Unsubscribe from realtime events.
  void unsubscribeFromRealtime() {
    _postsSubscription?.close();
    _commentsSubscription?.close();
    _postsSubscription = null;
    _commentsSubscription = null;
  }

  Future<void> loadPosts() async {
    final result = await _db.getPosts(limit: 200, offset: 0);
    _posts = result.rows.map((doc) {
      final d = doc.data;
      final commentsData = (d['comments'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // Determine image URL — check for imageFileId (Appwrite) or imagePath (local)
      String? imagePath = d['imagePath'] as String?;
      final imageFileId = d['imageFileId'] as String?;
      if (imageFileId != null && imageFileId.isNotEmpty) {
        imagePath = StorageService().getPostImageUrl(imageFileId);
      }

      return Post(
        id: doc.$id,
        username: (d['username'] as String?) ?? '',
        avatar: (d['avatar'] as String?) ?? '',
        imagePath: imagePath,
        caption: (d['caption'] as String?) ?? '',
        moodTag: d['moodTag'] as String?,
        postType: (d['postType'] as String?) ?? 'All',
        timestamp:
            DateTime.tryParse((d['timestamp'] as String?) ?? '') ??
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
    notifyListeners();
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
    String? imageFileId,
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
      imageFileId: imageFileId,
      moodTag: moodTag,
    );

    // Determine display image path
    String? displayImagePath = imagePath;
    if (imageFileId != null && imageFileId.isNotEmpty) {
      displayImagePath = StorageService().getPostImageUrl(imageFileId);
    }

    _posts.insert(
      0,
      Post(
        id: doc.$id,
        username: user.name.isNotEmpty ? user.name : 'you',
        avatar: user.name.isNotEmpty ? user.name[0].toUpperCase() : 'Y',
        imagePath: displayImagePath,
        caption: caption,
        moodTag: moodTag,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();

    // Send push notifications to other users
    _sendCommunityNotification(
      postId: doc.$id,
      authorId: user.$id,
      authorName: user.name.isNotEmpty ? user.name : 'someone',
      postTitle: caption,
    );
  }

  /// Send community update notification to all other users.
  /// Excludes the post creator to avoid self-notification.
  Future<void> _sendCommunityNotification({
    required String postId,
    required String authorId,
    required String authorName,
    required String postTitle,
  }) async {
    try {
      // Show local notification on this device
      await NotificationService().showCommunityPostNotification(
        postId: postId,
        authorName: authorName,
        postTitle: postTitle,
      );

      // Trigger server-side notifications via Appwrite Cloud Function
      await _triggerServerNotifications(
        postId: postId,
        authorId: authorId,
        authorName: authorName,
        postTitle: postTitle,
      );

      developer.log(
        'Community notification triggered for post: $postId',
        name: _tag,
      );
    } catch (e, st) {
      developer.log(
        'Failed to send community notification',
        name: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Trigger server-side push notifications via Appwrite.
  /// This calls a Cloud Function that sends FCM notifications to all users except the post creator.
  Future<void> _triggerServerNotifications({
    required String postId,
    required String authorId,
    required String authorName,
    required String postTitle,
  }) async {
    try {
      final appwrite = AppwriteService();
      final functions = appwrite.functions;

      // Call the cloud function to send notifications
      // The function will query all users, filter out the author, and send FCM notifications
      await functions.createExecution(
        functionId: 'sendCommunityNotifications',
        body: {
          'postId': postId,
          'authorId': authorId,
          'authorName': authorName,
          'postTitle': postTitle.length > 100
              ? '${postTitle.substring(0, 100)}...'
              : postTitle,
        }.toString(),
      );

      developer.log(
        'Server notification function triggered for post: $postId',
        name: _tag,
      );
    } catch (e, st) {
      // Log but don't fail - local notification was still sent
      developer.log(
        'Server notification function call failed (local notification was sent)',
        name: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> toggleLike(String postId) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final user = AuthService().currentUser;
    if (user == null) return;

    final post = _posts[idx];
    post.isLiked = !post.isLiked;
    post.likesCount += post.isLiked ? 1 : -1;
    notifyListeners();
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
    notifyListeners();
  }

  String formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  void dispose() {
    unsubscribeFromRealtime();
    super.dispose();
  }
}
