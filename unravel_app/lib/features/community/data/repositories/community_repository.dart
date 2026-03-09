import 'package:appwrite/appwrite.dart';
import '../../../../core/constants/appwrite_constants.dart';
import '../../domain/models/friend.dart';
import '../../domain/models/invite_code.dart';

class CommunityRepository {
  final Databases _databases;
  CommunityRepository(this._databases);

  Future<List<Friend>> getFriends() async {
    final response = await _databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.friendshipsCollection,
    );
    return response.documents.map((doc) => Friend.fromJson(doc.data)).toList();
  }

  Future<InviteCode> createInvite() async {
    final doc = await _databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.friendshipsCollection,
      documentId: ID.unique(),
      data: {'status': 'pending'},
    );
    return InviteCode.fromJson(doc.data);
  }

  Future<void> acceptInvite(String code) async {
    await _databases.updateDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.friendshipsCollection,
      documentId: code,
      data: {'status': 'accepted'},
    );
  }

  Future<void> toggleSharing(String id, bool enabled) async {
    await _databases.updateDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.friendshipsCollection,
      documentId: id,
      data: {'moodSharingEnabled': enabled},
    );
  }
}
