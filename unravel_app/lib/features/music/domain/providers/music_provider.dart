import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/appwrite_constants.dart';
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
      final functions = ref.read(appwriteFunctionsProvider);
      final execution = await functions.createExecution(
        functionId: AppwriteConstants.generatePlaylistFunction,
        body: jsonEncode({
          'quadrant': quadrant,
          'spotifyAccessToken': spotifyAccessToken,
        }),
      );
      final responseData = jsonDecode(execution.responseBody) as Map<String, dynamic>;
      final playlist = MoodPlaylist(
        id: responseData['playlistId'] ?? '',
        name: 'Unravel: $quadrant',
        spotifyUrl: responseData['playlistUrl'] as String,
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
