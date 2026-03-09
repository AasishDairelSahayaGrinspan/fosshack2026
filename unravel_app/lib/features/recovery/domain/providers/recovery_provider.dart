import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/appwrite_constants.dart';
import '../../../../core/providers/core_providers.dart';
import '../models/recovery_score.dart';

class RecoveryNotifier extends AsyncNotifier<RecoveryScore?> {
  @override
  Future<RecoveryScore?> build() async {
    try {
      final databases = ref.read(appwriteDatabasesProvider);
      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.recoveryScoresCollection,
        queries: [
          Query.orderDesc('date'),
          Query.limit(1),
        ],
      );
      if (response.documents.isNotEmpty) {
        return RecoveryScore.fromJson(response.documents.first.data);
      }
    } catch (_) {}
    return null;
  }

  Future<void> submitHealthData(Map<String, dynamic> data) async {
    try {
      final databases = ref.read(appwriteDatabasesProvider);
      await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.healthDataCollection,
        documentId: ID.unique(),
        data: data,
      );
      ref.invalidateSelf();
    } catch (_) {}
  }
}

final recoveryProvider = AsyncNotifierProvider<RecoveryNotifier, RecoveryScore?>(
  () => RecoveryNotifier(),
);

// Recovery history for charts
class RecoveryHistoryNotifier extends AsyncNotifier<List<RecoveryScore>> {
  @override
  Future<List<RecoveryScore>> build() async {
    try {
      final databases = ref.read(appwriteDatabasesProvider);
      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.recoveryScoresCollection,
        queries: [
          Query.orderDesc('date'),
          Query.limit(7),
        ],
      );
      return response.documents.map((doc) => RecoveryScore.fromJson(doc.data)).toList();
    } catch (_) {
      return [];
    }
  }
}

final recoveryHistoryProvider = AsyncNotifierProvider<RecoveryHistoryNotifier, List<RecoveryScore>>(
  () => RecoveryHistoryNotifier(),
);
