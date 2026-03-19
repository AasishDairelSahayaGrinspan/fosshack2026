import 'dart:developer' as developer;

import 'package:appwrite/models.dart' as models;

import 'storage_service.dart';

class MusicTrackData {
  final String id;
  final String title;
  final String artist;
  final String mood;
  final String sourceUrl;
  final bool fromCloud;

  const MusicTrackData({
    required this.id,
    required this.title,
    required this.artist,
    required this.mood,
    required this.sourceUrl,
    required this.fromCloud,
  });
}

class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  static const String _tag = 'MusicService';

  static const List<MusicTrackData> _localFallbackTracks = <MusicTrackData>[
    MusicTrackData(
      id: 'local_1',
      title: 'Calm Chill',
      artist: 'Armonicamente',
      mood: 'Calm',
      sourceUrl: 'assets/music/armonicamente-calm-chill-beautiful-141317.mp3',
      fromCloud: false,
    ),
    MusicTrackData(
      id: 'local_2',
      title: 'Aura Cycle',
      artist: 'Day Night Morning',
      mood: 'Focus',
      sourceUrl: 'assets/music/daynigthmorning-aura-273351.mp3',
      fromCloud: false,
    ),
    MusicTrackData(
      id: 'local_3',
      title: 'Soft Background',
      artist: 'Free Music For Video',
      mood: 'Release thoughts',
      sourceUrl: 'assets/music/freemusicforvideo-soft-background-music-409193.mp3',
      fromCloud: false,
    ),
    MusicTrackData(
      id: 'local_4',
      title: 'Calm Journey',
      artist: 'Happiness In Music',
      mood: 'Calm',
      sourceUrl: 'assets/music/happinessinmusic-music-calm-no-copyright-463752.mp3',
      fromCloud: false,
    ),
    MusicTrackData(
      id: 'local_5',
      title: 'Relaxing Session',
      artist: 'Happiness In Music',
      mood: 'Rest',
      sourceUrl: 'assets/music/happinessinmusic-relaxing-music-468109.mp3',
      fromCloud: false,
    ),
    MusicTrackData(
      id: 'local_6',
      title: '258 Hz Focus',
      artist: 'PoorArtistt',
      mood: 'Focus',
      sourceUrl: 'assets/music/poorartistt-258hz-frequency-music-no-copyright-music-for-meditation-amp-focus-339016.mp3',
      fromCloud: false,
    ),
  ];

  Future<List<MusicTrackData>> getPlayableTracks() async {
    final cloudTracks = await _loadCloudTracks();
    if (cloudTracks.isNotEmpty) return cloudTracks;
    return _localFallbackTracks;
  }

  Future<List<MusicTrackData>> _loadCloudTracks() async {
    try {
      final files = await StorageService().listMusicFiles(limit: 200);
      if (files.isEmpty) return <MusicTrackData>[];

      final seenNames = <String>{};
      final deduped = <models.File>[];
      for (final file in files) {
        if (seenNames.add(file.name)) {
          deduped.add(file);
        }
      }

      return deduped.map(_toTrackData).toList(growable: false);
    } catch (e, st) {
      developer.log(
        'Failed loading cloud tracks, using local fallback',
        name: _tag,
        error: e,
        stackTrace: st,
      );
      return <MusicTrackData>[];
    }
  }

  MusicTrackData _toTrackData(models.File file) {
    final name = file.name;
    final parsed = _parseName(name);

    return MusicTrackData(
      id: file.$id,
      title: parsed.$1,
      artist: parsed.$2,
      mood: parsed.$3,
      sourceUrl: StorageService().getMusicTrackUrl(file.$id),
      fromCloud: true,
    );
  }

  (String, String, String) _parseName(String rawName) {
    final cleaned = rawName
        .replaceAll('.mp3', '')
        .replaceAll('.wav', '')
        .replaceAll('.m4a', '')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();

    final title = cleaned
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase() + s.substring(1))
        .join(' ');

    final lower = cleaned.toLowerCase();
    final mood = lower.contains('focus')
        ? 'Focus'
        : lower.contains('calm')
            ? 'Calm'
            : lower.contains('relax')
                ? 'Rest'
                : 'Calm';

    return (title, 'Unravel Cloud', mood);
  }
}
