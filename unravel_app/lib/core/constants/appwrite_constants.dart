class AppwriteConstants {
  static const String endpoint = 'https://cloud.appwrite.io/v1';
  static const String projectId = 'YOUR_PROJECT_ID';
  static const String databaseId = 'unravel_db';

  // Collection IDs
  static const String moodLogsCollection = 'mood_logs';
  static const String journalEntriesCollection = 'journal_entries';
  static const String recoveryScoresCollection = 'recovery_scores';
  static const String healthDataCollection = 'health_data';
  static const String friendshipsCollection = 'friendships';

  // Function IDs
  static const String generatePlaylistFunction = 'generate-playlist';
  static const String computeRecoveryScoreFunction = 'compute-recovery-score';
}
