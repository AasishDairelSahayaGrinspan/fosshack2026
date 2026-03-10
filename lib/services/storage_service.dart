import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'appwrite_service.dart';
import 'appwrite_constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final Storage _storage = AppwriteService().storage;

  /// Upload a profile picture. Returns the file ID.
  Future<models.File> uploadProfilePic({
    required String userId,
    required String filePath,
    required String fileName,
  }) async {
    return await _storage.createFile(
      bucketId: AppwriteConstants.profilePicsBucket,
      fileId: userId, // One profile pic per user, overwrite by ID
      file: InputFile.fromPath(path: filePath, filename: fileName),
      permissions: [
        Permission.read(Role.any()),
        Permission.update(Role.user(userId)),
        Permission.delete(Role.user(userId)),
      ],
    );
  }

  /// Upload journal media (image). Returns the file model.
  Future<models.File> uploadJournalMedia({
    required String filePath,
    required String fileName,
    required String userId,
  }) async {
    return await _storage.createFile(
      bucketId: AppwriteConstants.journalMediaBucket,
      fileId: ID.unique(),
      file: InputFile.fromPath(path: filePath, filename: fileName),
      permissions: [
        Permission.read(Role.user(userId)),
        Permission.delete(Role.user(userId)),
      ],
    );
  }

  /// Upload a community post image.
  Future<models.File> uploadPostImage({
    required String filePath,
    required String fileName,
    required String userId,
  }) async {
    return await _storage.createFile(
      bucketId: AppwriteConstants.postImagesBucket,
      fileId: ID.unique(),
      file: InputFile.fromPath(path: filePath, filename: fileName),
      permissions: [
        Permission.read(Role.any()),
        Permission.delete(Role.user(userId)),
      ],
    );
  }

  /// Get a file preview/download URL.
  String getFilePreviewUrl(String bucketId, String fileId) {
    return '${AppwriteConstants.endpoint}/storage/buckets/$bucketId/files/$fileId/preview?project=${AppwriteConstants.projectId}';
  }

  /// Get the profile pic URL for a user.
  String getProfilePicUrl(String userId) {
    return getFilePreviewUrl(AppwriteConstants.profilePicsBucket, userId);
  }

  /// Get a post image URL.
  String getPostImageUrl(String fileId) {
    return getFilePreviewUrl(AppwriteConstants.postImagesBucket, fileId);
  }

  /// Download file as bytes.
  Future<Uint8List> downloadFile(String bucketId, String fileId) async {
    return await _storage.getFileDownload(
      bucketId: bucketId,
      fileId: fileId,
    );
  }

  /// Delete a file.
  Future<void> deleteFile(String bucketId, String fileId) async {
    await _storage.deleteFile(bucketId: bucketId, fileId: fileId);
  }
}
