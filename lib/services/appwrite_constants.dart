/// Central Appwrite configuration.
/// Replace placeholder values with your actual Appwrite project details.
class AppwriteConstants {
  AppwriteConstants._();

  // ─── Project ───
  static const String endpoint = 'https://cloud.appwrite.io/v1';
  static const String projectId = 'unravel-app';

  // ─── Database ───
  static const String databaseId = 'unravel_db';

  // ─── Collections ───
  static const String usersCollection = 'users';
  static const String moodEntriesCollection = 'mood_entries';
  static const String journalEntriesCollection = 'journal_entries';
  static const String streaksCollection = 'streaks';
  static const String recoveryScoresCollection = 'recovery_scores';
  static const String postsCollection = 'posts';
  static const String commentsCollection = 'comments';
  static const String sleepEntriesCollection = 'sleep_entries';
  static const String chatMessagesCollection = 'chat_messages';

  // ─── Storage Buckets ───
  static const String profilePicsBucket = 'profile_pics';
  static const String journalMediaBucket = 'journal_media';
  static const String postImagesBucket = 'post_images';
}
