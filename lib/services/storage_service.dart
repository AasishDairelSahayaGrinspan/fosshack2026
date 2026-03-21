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

  /// Get a direct file view URL suitable for audio/video playback.
  String getFileViewUrl(String bucketId, String fileId) {
    return '${AppwriteConstants.endpoint}/storage/buckets/$bucketId/files/$fileId/view?project=${AppwriteConstants.projectId}';
  }

  /// Get the profile pic URL for a user.
  String getProfilePicUrl(String userId) {
    return getFilePreviewUrl(AppwriteConstants.profilePicsBucket, userId);
  }

  /// Get a post image URL.
  String getPostImageUrl(String fileId) {
    return getFilePreviewUrl(AppwriteConstants.postImagesBucket, fileId);
  }

  /// Get an audio stream URL for a music track file.
  String getMusicTrackUrl(String fileId) {
    return getFileViewUrl(AppwriteConstants.musicBucket, fileId);
  }

  /// List cloud music files from Appwrite storage.
  Future<List<models.File>> listMusicFiles({int limit = 100}) async {
    final result = await _storage.listFiles(
      bucketId: AppwriteConstants.musicBucket,
      queries: [Query.limit(limit), Query.orderAsc(r'$createdAt')],
    );
    return result.files;
  }

  /// Download file as bytes.
  Future<Uint8List> downloadFile(String bucketId, String fileId) async {
    return await _storage.getFileDownload(bucketId: bucketId, fileId: fileId);
  }

  /// Delete a file.
  Future<void> deleteFile(String bucketId, String fileId) async {
    await _storage.deleteFile(bucketId: bucketId, fileId: fileId);
  }
}
