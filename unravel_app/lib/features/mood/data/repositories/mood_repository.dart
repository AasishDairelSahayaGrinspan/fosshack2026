import 'package:appwrite/appwrite.dart';
import '../../../../core/constants/appwrite_constants.dart';
import '../../domain/models/mood_entry.dart';

class MoodRepository {
  final Databases _databases;
  MoodRepository(this._databases);

  Future<MoodEntry> createMood(Map<String, dynamic> data) async {
    final doc = await _databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.moodLogsCollection,
      documentId: ID.unique(),
      data: data,
    );
    return MoodEntry.fromJson(doc.data);
  }

  Future<List<MoodEntry>> getMoodHistory() async {
    final result = await _databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.moodLogsCollection,
      queries: [Query.orderDesc('timestamp'), Query.limit(100)],
    );
    return result.documents.map((d) => MoodEntry.fromJson(d.data)).toList();
  }

  Future<void> syncUnsynced(List<MoodEntry> entries) async {
    for (final entry in entries) {
      await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.moodLogsCollection,
        documentId: ID.unique(),
        data: entry.toJson()..remove('synced'),
      );
    }
  }
}
