import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class PodcastScreen extends StatefulWidget {
  const PodcastScreen({super.key});

  @override
  State<PodcastScreen> createState() => _PodcastScreenState();
}

class _PodcastScreenState extends State<PodcastScreen> {
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  String _selectedCategory = 'All';
  int? _activeIndex;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  static const List<String> _categories = <String>[
    'All',
    'Meditation',
    'Breathing',
    'Sleep Stories',
    'Mindfulness',
    'Life & Wellness',
  ];

  static const List<_PodcastEpisode> _episodes = <_PodcastEpisode>[
    // Meditation
    _PodcastEpisode(
      title: 'Guided Meditation for Beginners',
      speaker: 'The Honest Guys',
      category: 'Meditation',
      durationLabel: '10 min',
      url: 'https://ia800500.us.archive.org/2/items/GuidedMeditationForBeginners/Guided_Meditation_For_Beginners.mp3',
    ),
    _PodcastEpisode(
      title: 'Morning Meditation',
      speaker: 'UCLA Mindful Awareness',
      category: 'Meditation',
      durationLabel: '12 min',
      url: 'https://ia600209.us.archive.org/14/items/MorningMeditation_201901/Morning%20Meditation.mp3',
    ),
    _PodcastEpisode(
      title: 'Loving Kindness Meditation',
      speaker: 'Tara Brach',
      category: 'Meditation',
      durationLabel: '15 min',
      url: 'https://ia800501.us.archive.org/18/items/LovingKindnessMeditation_201901/Loving%20Kindness%20Meditation.mp3',
    ),
    // Breathing
    _PodcastEpisode(
      title: 'Deep Breathing Exercise',
      speaker: 'Calm Space',
      category: 'Breathing',
      durationLabel: '8 min',
      url: 'https://ia800204.us.archive.org/28/items/DeepBreathingExercise/Deep_Breathing_Exercise.mp3',
    ),
    _PodcastEpisode(
      title: 'Box Breathing Guide',
      speaker: 'Breath Studio',
      category: 'Breathing',
      durationLabel: '7 min',
      url: 'https://ia600204.us.archive.org/28/items/BoxBreathingGuide/Box_Breathing_Guide.mp3',
    ),
    // Sleep Stories
    _PodcastEpisode(
      title: 'Sleep Meditation',
      speaker: 'Relaxation Channel',
      category: 'Sleep Stories',
      durationLabel: '20 min',
      url: 'https://ia800503.us.archive.org/3/items/SleepMeditation_201901/Sleep%20Meditation.mp3',
    ),
    _PodcastEpisode(
      title: 'Rain Sounds for Sleep',
      speaker: 'Nature Sounds',
      category: 'Sleep Stories',
      durationLabel: '30 min',
      url: 'https://ia800208.us.archive.org/30/items/RainSoundsForSleep/Rain_Sounds_For_Sleep.mp3',
    ),
    // Mindfulness
    _PodcastEpisode(
      title: 'Mindful Body Scan',
      speaker: 'Mindfulness Center',
      category: 'Mindfulness',
      durationLabel: '12 min',
      url: 'https://ia800502.us.archive.org/12/items/MindfulBodyScan/Mindful_Body_Scan.mp3',
    ),
    _PodcastEpisode(
      title: 'Present Moment Awareness',
      speaker: 'Thich Nhat Hanh Foundation',
      category: 'Mindfulness',
      durationLabel: '14 min',
      url: 'https://ia800503.us.archive.org/15/items/PresentMomentAwareness/Present_Moment_Awareness.mp3',
    ),
    _PodcastEpisode(
      title: 'Walking Meditation',
      speaker: 'Insight Timer',
      category: 'Mindfulness',
      durationLabel: '10 min',
      url: 'https://ia600502.us.archive.org/12/items/WalkingMeditationGuide/Walking_Meditation_Guide.mp3',
    ),
  ];

  List<_PodcastEpisode> get _filteredEpisodes {
    if (_selectedCategory == 'All') return _episodes;
    return _episodes
        .where((e) => e.category == _selectedCategory)
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _playerStateSub = _player.playerStateStream.listen((_) {
      if (mounted) setState(() {});
    });
    _positionSub = _player.positionStream.listen((value) {
      if (!mounted) return;
      setState(() => _position = value);
    });
    _durationSub = _player.durationStream.listen((value) {
      if (!mounted) return;
      setState(() => _duration = value ?? Duration.zero);
    });
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _playOrPause(_PodcastEpisode episode) async {
    final index = _episodes.indexOf(episode);
    if (index < 0) return;

    if (_activeIndex == index) {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _activeIndex = index;
      _position = Duration.zero;
      _duration = Duration.zero;
    });

    try {
      await _player.setUrl(episode.url);
      await _player.play();
    } catch (e, st) {
      developer.log(
        'Podcast playback failed',
        name: 'PodcastScreen',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      
      // Parse error for better user messaging
      String errorMessage = 'Could not play this episode.';
      final errorStr = e.toString().toLowerCase();
      
      if (errorStr.contains('network') || errorStr.contains('socket') || 
          errorStr.contains('connection') || errorStr.contains('unreachable')) {
        errorMessage = 'Network error. Check your internet connection.';
      } else if (errorStr.contains('timeout')) {
        errorMessage = 'Connection timeout. Please try again.';
      } else if (errorStr.contains('format') || errorStr.contains('unsupported')) {
        errorMessage = 'Audio format not supported.';
      } else if (errorStr.contains('404') || errorStr.contains('not found')) {
        errorMessage = 'Episode not available.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: AppTypography.body(color: Colors.white),
          ),
          backgroundColor: AppColors.warmCoral,
          duration: const Duration(seconds: 4),
        ),
      );
      setState(() => _activeIndex = null);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDuration(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final activeEpisode =
        _activeIndex != null &&
            _activeIndex! >= 0 &&
            _activeIndex! < _episodes.length
        ? _episodes[_activeIndex!]
        : null;
    final progressMax = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds.toDouble()
        : 1.0;
    final progressValue = _position.inMilliseconds
        .clamp(0, progressMax.toInt())
        .toDouble();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.bgGradient(context),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _buildTopBar(context),
              _buildCategoryChips(context),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  itemCount: _filteredEpisodes.length,
                  itemBuilder: (context, i) {
                    final episode = _filteredEpisodes[i];
                    return _buildEpisodeCard(context, episode);
                  },
                ),
              ),
              if (activeEpisode != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    border: Border.all(
                      color: AppColors.softIndigo.withValues(alpha: 0.28),
                    ),
                    boxShadow: AppColors.subtleShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        activeEpisode.title,
                        style: AppTypography.uiLabelC(context),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${activeEpisode.speaker}  -  ${activeEpisode.category}',
                        style: AppTypography.captionC(context),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          IconButton(
                            onPressed: () {
                              if (_player.playing) {
                                _player.pause();
                              } else {
                                _player.play();
                              }
                            },
                            icon: Icon(
                              _player.playing
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              color: AppColors.softIndigo,
                              size: 44,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () async {
                              await _player.stop();
                              setState(() => _activeIndex = null);
                            },
                            icon: const Icon(
                              Icons.stop_circle_outlined,
                              color: AppColors.softIndigo,
                              size: 44,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: progressValue,
                          min: 0,
                          max: progressMax,
                          activeColor: AppColors.softIndigo,
                          inactiveColor: AppColors.dividerColor(context),
                          onChanged: (value) {
                            _player.seek(Duration(milliseconds: value.toInt()));
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            _formatDuration(_position),
                            style: AppTypography.captionC(context),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: AppTypography.captionC(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.softIndigo.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.softIndigo,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Podcast',
              style: AppTypography.sectionHeadingC(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final category = _categories[i];
          final isSelected = category == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: AnimatedContainer(
              duration: AppTheme.fadeInDuration,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.softIndigo.withValues(alpha: 0.16)
                    : AppColors.card(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                border: Border.all(
                  color: isSelected
                      ? AppColors.softIndigo.withValues(alpha: 0.45)
                      : AppColors.dividerColor(context),
                ),
              ),
              child: Center(
                child: Text(
                  category,
                  style: AppTypography.caption(
                    color: isSelected
                        ? AppColors.softIndigo
                        : AppColors.secondary(context),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEpisodeCard(BuildContext context, _PodcastEpisode episode) {
    final index = _episodes.indexOf(episode);
    final isActive = _activeIndex == index;
    final isPlaying = isActive && _player.playing;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: isActive
              ? AppColors.softIndigo.withValues(alpha: 0.45)
              : AppColors.cardBorder(context),
          width: 1,
        ),
        boxShadow: AppColors.cardShadow(context),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.softIndigo.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.podcasts_rounded,
              color: AppColors.softIndigo,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(episode.title, style: AppTypography.uiLabelC(context)),
                const SizedBox(height: 2),
                Text(
                  '${episode.speaker}  -  ${episode.durationLabel}',
                  style: AppTypography.captionC(context),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _isLoading ? null : () => _playOrPause(episode),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.softIndigo.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: _isLoading && isActive
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.softIndigo.withValues(alpha: 0.9),
                      ),
                    )
                  : Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: AppColors.softIndigo,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PodcastEpisode {
  final String title;
  final String speaker;
  final String category;
  final String durationLabel;
  final String url;

  const _PodcastEpisode({
    required this.title,
    required this.speaker,
    required this.category,
    required this.durationLabel,
    required this.url,
  });
}
