import 'package:dio/dio.dart';
import '../../domain/models/playlist.dart';

class MusicRepository {
  final Dio _dio;
  MusicRepository(this._dio);

  Future<MoodPlaylist> generatePlaylist(
      String quadrant, String? spotifyToken) async {
    final response = await _dio.post('/music/playlist', data: {
      'quadrant': quadrant,
      if (spotifyToken != null) 'spotifyToken': spotifyToken,
    });
    return MoodPlaylist.fromJson(response.data);
  }
}
