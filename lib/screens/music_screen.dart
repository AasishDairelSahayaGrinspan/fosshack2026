import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:just_audio/just_audio.dart';

import '../services/app_navigation_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/music_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/doodle_refresh.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final AudioPlayer _player = AudioPlayer();
  final MusicService _musicService = MusicService();

  List<MusicTrackData> _tracks = const <MusicTrackData>[];
  String? _recommendation;
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _recommendation = AppNavigationService().musicRecommendation.value;
    AppNavigationService().musicRecommendation.addListener(_onRecommendation);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final tracks = await _musicService.getPlayableTracks();
      if (tracks.isEmpty) {
        if (!mounted) return;
        setState(() {
          _tracks = const <MusicTrackData>[];
          _error = 'No tracks found in cloud or local assets.';
          _isLoading = false;
        });
        return;
      }

      final sources = tracks.map((t) {
        if (t.fromCloud) {
          return AudioSource.uri(Uri.parse(t.sourceUrl));
        }
        return AudioSource.asset(t.sourceUrl);
      }).toList(growable: false);

      await _player.setAudioSource(ConcatenatingAudioSource(children: sources));

      _player.currentIndexStream.listen((index) {
        if (!mounted || index == null) return;
        setState(() => _currentIndex = index);
      });

      if (!mounted) return;
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    } catch (e, st) {
      developer.log(
        'Music bootstrap failed',
        name: 'MusicScreen',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load music. Pull to retry.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    AppNavigationService().musicRecommendation.removeListener(_onRecommendation);
    _player.dispose();
    super.dispose();
  }

  void _onRecommendation() {
    if (!mounted) return;
    setState(() {
      _recommendation = AppNavigationService().musicRecommendation.value;
    });
  }

  Future<void> _playTrack(int index) async {
    if (_isLoading || _tracks.isEmpty) return;

    await _player.seek(Duration.zero, index: index);
    await _player.play();

    final user = AuthService().currentUser;
    if (user != null) {
      final track = _tracks[index];
      await DatabaseService().saveListenedSong(
        userId: user.$id,
        title: track.title,
        artist: track.artist,
        playlist: track.fromCloud ? 'Unravel Cloud Music' : 'Unravel Local Music',
        mood: track.mood,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E2A38), Color(0xFF38546B), Color(0xFF7A8FA8)],
          ),
        ),
        child: SafeArea(
          child: DoodleRefresh(
            onRefresh: _bootstrap,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),
                  Text(
                    'Sound Space',
                    style: AppTypography.heroHeading(color: Colors.white),
                  ).animate().fadeIn(duration: const Duration(milliseconds: 350)),
                  const SizedBox(height: 6),
                  Text(
                    'Cloud-first playback from Appwrite storage.',
                    style: AppTypography.subtitle(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_recommendation != null) ...[
                    _buildRecommendationCard(),
                    const SizedBox(height: 16),
                  ],
                  if (_isLoading)
                    _buildLoadingCard()
                  else if (_error != null)
                    _buildErrorCard()
                  else ...[
                    _buildNowPlayingCard(),
                    const SizedBox(height: 20),
                    Text(
                      'Library',
                      style: AppTypography.sectionHeading(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tracks.first.fromCloud
                          ? 'Streaming from Appwrite cloud.'
                          : 'Using local fallback tracks.',
                      style: AppTypography.caption(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_tracks.length, _buildTrackRow),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amberFdb903.withValues(alpha: 0.17),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.amberFdb903.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 18,
            color: AppColors.amberFdb903,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _recommendation!,
              style: AppTypography.caption(color: Colors.white),
            ),
          ),
          IconButton(
            onPressed: () => AppNavigationService().clearMusicRecommendation(),
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading cloud music...',
            style: AppTypography.uiLabel(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error ?? 'Unknown music error.',
              style: AppTypography.caption(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: _bootstrap,
            child: Text(
              'Retry',
              style: AppTypography.caption(color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlayingCard() {
    final current = _tracks[_currentIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Now Playing',
            style: AppTypography.caption(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            current.title,
            style: AppTypography.sectionHeading(color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            '${current.artist} · ${current.mood}',
            style: AppTypography.caption(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          StreamBuilder<Duration?>(
            stream: _player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = _player.duration ?? const Duration(seconds: 1);
              final maxMs = duration.inMilliseconds <= 0
                ? 1.0
                : duration.inMilliseconds.toDouble();
              final value = position.inMilliseconds
                .clamp(0, duration.inMilliseconds)
                .toDouble();

              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                      overlayColor: Colors.white24,
                    ),
                    child: Slider(
                      value: value,
                      max: maxMs,
                      onChanged: (v) {
                        _player.seek(Duration(milliseconds: v.round()));
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_fmt(position), style: AppTypography.caption(color: Colors.white70)),
                      Text(_fmt(duration), style: AppTypography.caption(color: Colors.white70)),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () async {
                  if (_player.hasPrevious) {
                    await _player.seekToPrevious();
                    await _player.play();
                  }
                },
                icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 10),
              StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data?.playing ?? false;
                  return InkWell(
                    onTap: () async {
                      if (isPlaying) {
                        await _player.pause();
                      } else {
                        await _player.play();
                      }
                    },
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: const Color(0xFF1E2A38),
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () async {
                  if (_player.hasNext) {
                    await _player.seekToNext();
                    await _player.play();
                  }
                },
                icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackRow(int index) {
    final track = _tracks[index];
    final isCurrent = index == _currentIndex;

    return GestureDetector(
      onTap: () => _playTrack(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isCurrent
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isCurrent
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCurrent ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded,
                size: 20,
                color: isCurrent ? const Color(0xFF1E2A38) : Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: AppTypography.uiLabel(color: Colors.white),
                  ),
                  Text(
                    '${track.artist} · ${track.mood}',
                    style: AppTypography.caption(
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            if (track.fromCloud)
              const Icon(Icons.cloud_done_rounded, size: 16, color: Colors.white70)
            else
              const Icon(Icons.phone_iphone_rounded, size: 16, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  String _fmt(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
