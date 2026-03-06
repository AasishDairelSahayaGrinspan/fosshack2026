import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../mood/domain/providers/mood_provider.dart';
import '../../domain/providers/music_provider.dart';

class MusicScreen extends ConsumerWidget {
  const MusicScreen({super.key});

  Color _quadrantColor(String? quadrant) {
    switch (quadrant) {
      case 'highEnergyPleasant':
        return AppColors.highEnergyPleasant;
      case 'highEnergyUnpleasant':
        return AppColors.highEnergyUnpleasant;
      case 'lowEnergyUnpleasant':
        return AppColors.lowEnergyUnpleasant;
      case 'lowEnergyPleasant':
        return AppColors.lowEnergyPleasant;
      default:
        return Colors.grey;
    }
  }

  String _quadrantLabel(String? quadrant) {
    switch (quadrant) {
      case 'highEnergyPleasant':
        return 'High Energy, Pleasant';
      case 'highEnergyUnpleasant':
        return 'High Energy, Unpleasant';
      case 'lowEnergyUnpleasant':
        return 'Low Energy, Unpleasant';
      case 'lowEnergyPleasant':
        return 'Low Energy, Pleasant';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMood = ref.watch(currentMoodProvider);
    final currentQuadrant = currentMood?.quadrant;
    final playlistState = ref.watch(musicProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Music')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current mood quadrant display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _quadrantColor(currentQuadrant),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      currentQuadrant != null
                          ? 'Current Mood: ${_quadrantLabel(currentQuadrant)}'
                          : 'No mood logged yet',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Generate playlist button
            ElevatedButton.icon(
              onPressed: currentQuadrant == null
                  ? null
                  : () async {
                      await ref.read(musicProvider.notifier).generatePlaylist(
                        quadrant: currentQuadrant,
                        spotifyAccessToken: '', // TODO: pass Spotify token when auth is implemented
                      );
                    },
              icon: const Icon(Icons.music_note),
              label: const Text('Generate Playlist'),
            ),
            const SizedBox(height: 24),

            // Playlist result
            playlistState.when(
              data: (playlist) {
                if (playlist == null) return const SizedBox.shrink();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('${playlist.trackCount} tracks'),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: playlist.spotifyUrl));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('URL copied to clipboard')),
                            );
                          },
                          child: Text(
                            playlist.spotifyUrl,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }
}
