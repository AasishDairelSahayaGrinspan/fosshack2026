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
      title: 'Ambient Calm',
      artist: 'Unravel Music',
      mood: 'Calm',
      sourceUrl: 'assets/music/Ambient Calm.mp3',
      fromCloud: false,
    ),
    MusicTrackData(
      id: 'local_2',
      title: 'Morning Aura',
      artist: 'Unravel Music',
      mood: 'Energy',
      sourceUrl: 'assets/music/Morning Aura.mp3',
      fromCloud: false,
    ),
    MusicTrackData(
      id: 'local_3',
      title: 'Soft Background',
      artist: 'Unravel Music',
      mood: 'Peaceful',
      sourceUrl: 'assets/music/Soft Background.mp3',
      fromCloud: false,
    ),
    MusicTrackData(
      id: 'local_4',
      title: 'Peaceful Moments',
      artist: 'Unravel Music',
      mood: 'Calm',
      sourceUrl: 'assets/music/Peaceful Moments.mp3',
      fromCloud: false,
    ),
    MusicTrackData(
      id: 'local_5',
      title: 'Relaxing Music',
      artist: 'Unravel Music',
      mood: 'Rest',
      sourceUrl: 'assets/music/Relaxing Music.mp3',
      fromCloud: false,
    ),
    MusicTrackData(
      id: 'local_6',
      title: 'Meditation Focus',
      artist: 'Unravel Music',
      mood: 'Focus',
      sourceUrl: 'assets/music/Meditation Focus.mp3',
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
    final normalized = rawName.toLowerCase();

    const knownTracks = <String, (String, String, String)>{
      'armonicamente-calm-chill-beautiful-141317.mp3':
        ('Ambient Calm', 'Unravel Music', 'Calm'),
      'daynigthmorning-aura-273351.mp3':
        ('Morning Aura', 'Unravel Music', 'Energy'),
      'freemusicforvideo-soft-background-music-409193.mp3':
        ('Soft Background', 'Unravel Music', 'Peaceful'),
      'happinessinmusic-music-calm-no-copyright-463752.mp3':
        ('Peaceful Moments', 'Unravel Music', 'Calm'),
      'happinessinmusic-relaxing-music-468109.mp3':
        ('Relaxing Music', 'Unravel Music', 'Rest'),
      'poorartistt-258hz-frequency-music-no-copyright-music-for-meditation-amp-focus-339016.mp3':
        ('Meditation Focus', 'Unravel Music', 'Focus'),
      'ambient calm.mp3': ('Ambient Calm', 'Unravel Music', 'Calm'),
      'morning aura.mp3': ('Morning Aura', 'Unravel Music', 'Energy'),
      'soft background.mp3': ('Soft Background', 'Unravel Music', 'Peaceful'),
      'peaceful moments.mp3': ('Peaceful Moments', 'Unravel Music', 'Calm'),
      'relaxing music.mp3': ('Relaxing Music', 'Unravel Music', 'Rest'),
      'meditation focus.mp3': ('Meditation Focus', 'Unravel Music', 'Focus'),
    };

    final known = knownTracks[normalized];
    if (known != null) return known;

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
