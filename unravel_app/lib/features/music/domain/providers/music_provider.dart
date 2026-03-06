import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../models/playlist.dart';

class MusicNotifier extends AsyncNotifier<MoodPlaylist?> {
  @override
  Future<MoodPlaylist?> build() async => null;

  Future<MoodPlaylist> generatePlaylist({
    required String quadrant,
    required String spotifyAccessToken,
  }) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/music/playlist', data: {
        'quadrant': quadrant,
        'spotifyAccessToken': spotifyAccessToken,
      });
      final playlist = MoodPlaylist(
        id: response.data['playlistId'] ?? '',
        name: 'Unravel: $quadrant',
        spotifyUrl: response.data['playlistUrl'] as String,
        quadrant: quadrant,
        createdAt: DateTime.now(),
      );
      state = AsyncData(playlist);
      return playlist;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}

final musicProvider = AsyncNotifierProvider<MusicNotifier, MoodPlaylist?>(
  () => MusicNotifier(),
);
