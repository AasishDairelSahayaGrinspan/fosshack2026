import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/appwrite_constants.dart';
import '../../../../core/providers/core_providers.dart';
import '../models/friend.dart';

class CommunityNotifier extends AsyncNotifier<List<Friend>> {
  @override
  Future<List<Friend>> build() async {
    try {
      final databases = ref.read(appwriteDatabasesProvider);
      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.friendshipsCollection,
      );
      return response.documents.map((doc) => Friend.fromJson(doc.data)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String> generateInvite() async {
    final databases = ref.read(appwriteDatabasesProvider);
    final doc = await databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.friendshipsCollection,
      documentId: ID.unique(),
      data: {'status': 'pending'},
    );
    return doc.$id;
  }

  Future<void> acceptInvite(String encryptedCode) async {
    final databases = ref.read(appwriteDatabasesProvider);
    await databases.updateDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.friendshipsCollection,
      documentId: encryptedCode,
      data: {'status': 'accepted'},
    );
    ref.invalidateSelf();
  }

  Future<void> toggleMoodSharing(String friendshipId, bool enabled) async {
    final databases = ref.read(appwriteDatabasesProvider);
    await databases.updateDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.friendshipsCollection,
      documentId: friendshipId,
      data: {'moodSharingEnabled': enabled},
    );
    ref.invalidateSelf();
  }
}

final communityProvider = AsyncNotifierProvider<CommunityNotifier, List<Friend>>(
  () => CommunityNotifier(),
);
