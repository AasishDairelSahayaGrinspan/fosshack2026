import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import '../../../../core/constants/appwrite_constants.dart';
import '../../domain/models/playlist.dart';

class MusicRepository {
  final Functions _functions;
  MusicRepository(this._functions);

  Future<MoodPlaylist> generatePlaylist(
      String quadrant, String? spotifyToken) async {
    final execution = await _functions.createExecution(
      functionId: AppwriteConstants.generatePlaylistFunction,
      body: jsonEncode({
        'quadrant': quadrant,
        if (spotifyToken != null) 'spotifyToken': spotifyToken,
      }),
    );
    final data = jsonDecode(execution.responseBody) as Map<String, dynamic>;
    return MoodPlaylist.fromJson(data);
  }
}
