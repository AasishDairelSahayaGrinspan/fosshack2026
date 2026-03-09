import 'package:appwrite/appwrite.dart';
import '../../../../core/constants/appwrite_constants.dart';
import '../../domain/models/recovery_score.dart';

class RecoveryRepository {
  final Databases _databases;
  RecoveryRepository(this._databases);

  Future<RecoveryScore> submitHealthData(Map<String, dynamic> data) async {
    final doc = await _databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.healthDataCollection,
      documentId: ID.unique(),
      data: data,
    );
    return RecoveryScore.fromJson(doc.data);
  }

  Future<RecoveryScore?> getLatestScore() async {
    final response = await _databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.recoveryScoresCollection,
      queries: [
        Query.orderDesc('date'),
        Query.limit(1),
      ],
    );
    if (response.documents.isEmpty) return null;
    return RecoveryScore.fromJson(response.documents.first.data);
  }

  Future<List<RecoveryScore>> getScoreHistory(int days) async {
    final response = await _databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.recoveryScoresCollection,
      queries: [
        Query.orderDesc('date'),
        Query.limit(days),
      ],
    );
    return response.documents.map((doc) => RecoveryScore.fromJson(doc.data)).toList();
  }
}
