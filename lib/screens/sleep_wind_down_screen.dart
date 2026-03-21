import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:just_audio/just_audio.dart';
import '../constants/lottie_urls.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

/// Sleep Wind Down Screen with bedtime relaxation routine
class SleepWindDownScreen extends StatefulWidget {
  const SleepWindDownScreen({super.key});

  @override
  State<SleepWindDownScreen> createState() => _SleepWindDownScreenState();
}

class _SleepWindDownScreenState extends State<SleepWindDownScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _ambientSoundEnabled = true;
  DateTime? _sessionStart;
  late AnimationController _starAnimController;

  // Sleep wind down activities
  static const List<Map<String, dynamic>> _windDownActivities = [
    {
      'icon': Icons.bedtime_rounded,
      'title': 'Dim the Lights',
      'description': 'Create a calm environment by reducing light exposure.',
      'duration': '2 min',
    },
    {
      'icon': Icons.air_rounded,
      'title': 'Deep Breathing',
      'description': 'Take slow, deep breaths to signal your body it\'s time to rest.',
      'duration': '5 min',
    },
    {
      'icon': Icons.book_outlined,
      'title': 'Gratitude Reflection',
      'description': 'Think of 3 things you\'re grateful for today.',
      'duration': '3 min',
    },
    {
      'icon': Icons.self_improvement_rounded,
      'title': 'Progressive Relaxation',
      'description': 'Relax each muscle group from head to toe.',
      'duration': '8 min',
    },
    {
      'icon': Icons.nightlight_outlined,
      'title': 'Visualization',
      'description': 'Imagine a peaceful, calming scene.',
      'duration': '5 min',
    },
  ];

  int _currentActivityIndex = 0;

  // Sleep stories
  static const List<Map<String, String>> _sleepStories = [
    {
      'title': 'Starlit Forest',
      'description': 'A gentle walk through a peaceful forest under the stars.',
      'url': 'https://assets.mixkit.co/active_storage/sfx/2390/2390-preview.mp3',
    },
    {
      'title': 'Ocean Waves',
      'description': 'Drifting to sleep with the sound of gentle ocean waves.',
      'url': 'https://assets.mixkit.co/active_storage/sfx/2390/2390-preview.mp3',
    },
    {
      'title': 'Rain on Rooftop',
      'description': 'Cozy rain sounds to help you relax and sleep.',
      'url': 'https://assets.mixkit.co/active_storage/sfx/2390/2390-preview.mp3',
    },
  ];

  int _selectedStoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _starAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _starAnimController.dispose();
    _stopSession();
    super.dispose();
  }

  Future<void> _startSession() async {
    setState(() {
      _isPlaying = true;
      _sessionStart = DateTime.now();
    });

    if (_ambientSoundEnabled) {
      try {
        final story = _sleepStories[_selectedStoryIndex];
        await _audioPlayer.setUrl(story['url']!);
        await _audioPlayer.setLoopMode(LoopMode.all);
        await _audioPlayer.play();
      } catch (e) {
        developer.log('Failed to play sleep story', name: 'SleepWindDownScreen', error: e);
      }
    }

    _startActivityCycle();
  }

  void _stopSession() {
    if (_sessionStart != null) {
      final duration = DateTime.now().difference(_sessionStart!).inSeconds;
      final user = AuthService().currentUser;
      if (user != null && duration > 10) {
        // Save as sleep log
        DatabaseService().saveSleepLog(
          userId: user.$id,
          hours: duration / 3600, // Convert seconds to hours
          dreamType: 'none',
          dreamDescription: 'Sleep wind-down session',
        );
      }
      _sessionStart = null;
    }
  }

  void _pauseSession() async {
    await _audioPlayer.pause();
    setState(() => _isPlaying = false);
  }

  void _resumeSession() async {
    await _audioPlayer.play();
    setState(() => _isPlaying = true);
  }

  void _endSession() async {
    _stopSession();
    await _audioPlayer.stop();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _currentActivityIndex = 0;
      });
    }
  }

  void _startActivityCycle() {
    if (!_isPlaying) return;
    Future.delayed(const Duration(seconds: 60), () {
      if (_isPlaying && mounted) {
        setState(() {
          if (_currentActivityIndex < _windDownActivities.length - 1) {
            _currentActivityIndex++;
          }
        });
        _startActivityCycle();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildMoonAnimation(),
                    const SizedBox(height: 30),
                    if (_isPlaying) ...[
                      _buildCurrentActivityCard(),
                      const SizedBox(height: 20),
                      _buildProgressIndicator(),
                    ] else ...[
                      _buildStorySelector(),
                      const SizedBox(height: 20),
                      _buildActivitiesPreview(),
                    ],
                    const SizedBox(height: 30),
                    _buildControls(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: AppColors.primary(context),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Sleep Wind-Down',
            style: AppTypography.sectionHeadingC(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMoonAnimation() {
    return Container(
      height: 220,
      width: 220,
      decoration: BoxDecoration(
        color: AppColors.card(context),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.warmCoral.withValues(alpha: 0.3),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Lottie.network(
            LottieUrls.stars,
            width: 200,
            height: 200,
            fit: BoxFit.contain,
            repeat: true,
          ),
          Lottie.network(
            LottieUrls.moon,
            width: 120,
            height: 120,
            fit: BoxFit.contain,
            repeat: true,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 800.ms,
        );
  }

  Widget _buildCurrentActivityCard() {
    final activity = _windDownActivities[_currentActivityIndex];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warmCoral.withValues(alpha: 0.2),
            AppColors.softIndigo.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: AppColors.warmCoral.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            activity['icon'] as IconData,
            color: AppColors.warmCoral,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            activity['title'] as String,
            style: AppTypography.subtitleC(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            activity['description'] as String,
            style: AppTypography.bodyC(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warmCoral.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              activity['duration'] as String,
              style: AppTypography.captionC(context)
                  .copyWith(color: AppColors.warmCoral),
            ),
          ),
        ],
      ),
    ).animate(key: ValueKey(_currentActivityIndex))
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.2, end: 0, duration: 600.ms);
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_windDownActivities.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: index == _currentActivityIndex ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: index <= _currentActivityIndex
                    ? AppColors.warmCoral
                    : AppColors.dividerColor(context),
                borderRadius: BorderRadius.circular(4),
              ),
            ).animate().fadeIn();
          }),
        ),
        const SizedBox(height: 12),
        Text(
          'Step ${_currentActivityIndex + 1} of ${_windDownActivities.length}',
          style: AppTypography.captionC(context),
        ),
      ],
    );
  }

  Widget _buildStorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Sleep Story',
          style: AppTypography.subtitleC(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_sleepStories.length, (index) {
          final story = _sleepStories[index];
          final isSelected = index == _selectedStoryIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedStoryIndex = index),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(
                  color: isSelected
                      ? AppColors.warmCoral
                      : AppColors.dividerColor(context),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.nightlight_rounded,
                    color: isSelected
                        ? AppColors.warmCoral
                        : AppColors.secondary(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story['title']!,
                          style: AppTypography.bodyC(context).copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          story['description']!,
                          style: AppTypography.captionC(context),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.warmCoral,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActivitiesPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wind-Down Activities',
          style: AppTypography.subtitleC(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_windDownActivities.length, (index) {
          final activity = _windDownActivities[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  activity['icon'] as IconData,
                  color: AppColors.warmCoral,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    activity['title'] as String,
                    style: AppTypography.bodyC(context),
                  ),
                ),
                Text(
                  activity['duration'] as String,
                  style: AppTypography.captionC(context),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        // Main control button
        GestureDetector(
          onTap: () {
            if (!_isPlaying && _sessionStart == null) {
              _startSession();
            } else if (_isPlaying) {
              _pauseSession();
            } else {
              _resumeSession();
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.warmCoral,
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            ),
            child: Center(
              child: Text(
                _sessionStart == null
                    ? 'Begin Wind-Down'
                    : _isPlaying
                        ? 'Pause'
                        : 'Resume',
                style: AppTypography.buttonText(color: Colors.white),
              ),
            ),
          ),
        ),
        if (_sessionStart != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _endSession,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                border: Border.all(
                  color: AppColors.dividerColor(context),
                ),
              ),
              child: Center(
                child: Text(
                  'End Session',
                  style: AppTypography.buttonText(
                    color: AppColors.primary(context),
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        // Ambient sound toggle
        GestureDetector(
          onTap: () {
            setState(() => _ambientSoundEnabled = !_ambientSoundEnabled);
            if (_isPlaying) {
              if (_ambientSoundEnabled) {
                _audioPlayer.play();
              } else {
                _audioPlayer.pause();
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
              border: Border.all(
                color: _ambientSoundEnabled
                    ? AppColors.warmCoral
                    : AppColors.dividerColor(context),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _ambientSoundEnabled ? Icons.volume_up : Icons.volume_off,
                  color: _ambientSoundEnabled
                      ? AppColors.warmCoral
                      : AppColors.secondary(context),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sleep Story Audio',
                  style: AppTypography.bodyC(context).copyWith(
                    color: _ambientSoundEnabled
                        ? AppColors.warmCoral
                        : AppColors.secondary(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
