import 'package:appwrite/appwrite.dart';
import '../../../../core/constants/appwrite_constants.dart';
import '../../domain/models/journal_entry.dart';

class JournalRepository {
  final Databases _databases;
  JournalRepository(this._databases);

  Future<JournalEntry> createEntry(Map<String, dynamic> data) async {
    final doc = await _databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.journalEntriesCollection,
      documentId: ID.unique(),
      data: data,
    );
    return JournalEntry.fromJson(doc.data);
  }

  Future<List<JournalEntry>> getEntries() async {
    final result = await _databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.journalEntriesCollection,
      queries: [Query.orderDesc('timestamp'), Query.limit(100)],
    );
    return result.documents.map((d) => JournalEntry.fromJson(d.data)).toList();
  }

  Future<void> syncUnsynced(List<JournalEntry> entries) async {
    for (final entry in entries) {
      await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.journalEntriesCollection,
        documentId: ID.unique(),
        data: entry.toJson(),
      );
    }
  }
}
