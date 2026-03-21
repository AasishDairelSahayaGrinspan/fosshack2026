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

/// Mindful Walk Screen with guided walking meditation
class MindfulWalkScreen extends StatefulWidget {
  const MindfulWalkScreen({super.key});

  @override
  State<MindfulWalkScreen> createState() => _MindfulWalkScreenState();
}

class _MindfulWalkScreenState extends State<MindfulWalkScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isWalking = false;
  bool _ambientSoundEnabled = true;
  DateTime? _sessionStart;
  int _stepCount = 0;
  late AnimationController _walkAnimController;

  // Walking meditation prompts
  static const List<Map<String, String>> _walkingPrompts = [
    {
      'title': 'Begin with Awareness',
      'description': 'Feel your feet connecting with the ground. Notice each step.',
    },
    {
      'title': 'Breathe and Walk',
      'description': 'Synchronize your breath with your steps. Inhale for 2 steps, exhale for 2.',
    },
    {
      'title': 'Notice Your Surroundings',
      'description': 'Observe the sounds, sights, and smells around you without judgment.',
    },
    {
      'title': 'Body Scan While Walking',
      'description': 'Notice sensations in your legs, arms, and core as you move.',
    },
    {
      'title': 'Mindful Gratitude',
      'description': 'With each step, think of something you\'re grateful for.',
    },
  ];

  int _currentPromptIndex = 0;

  @override
  void initState() {
    super.initState();
    _walkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _walkAnimController.dispose();
    _stopSession();
    super.dispose();
  }

  Future<void> _startWalking() async {
    setState(() {
      _isWalking = true;
      _sessionStart = DateTime.now();
      _stepCount = 0;
    });
    _walkAnimController.repeat(reverse: true);
    
    if (_ambientSoundEnabled) {
      try {
        await _audioPlayer.setUrl(
          'https://assets.mixkit.co/active_storage/sfx/2390/2390-preview.mp3',
        );
        await _audioPlayer.setLoopMode(LoopMode.all);
        await _audioPlayer.play();
      } catch (e) {
        developer.log('Failed to play ambient sound', name: 'MindfulWalkScreen', error: e);
      }
    }

    _startPromptCycle();
  }

  void _stopWalking() async {
    _stopSession();
    await _audioPlayer.stop();
    _walkAnimController.stop();
    if (mounted) {
      setState(() {
        _isWalking = false;
      });
    }
  }

  void _stopSession() {
    if (_sessionStart != null) {
      final duration = DateTime.now().difference(_sessionStart!).inSeconds;
      final user = AuthService().currentUser;
      if (user != null && duration > 10) {
        // Save as breathing session since there's no general activity log
        DatabaseService().saveBreathingSession(
          userId: user.$id,
          durationSeconds: duration,
          ambientEnabled: _ambientSoundEnabled,
        );
      }
      _sessionStart = null;
    }
  }

  void _startPromptCycle() {
    if (!_isWalking) return;
    Future.delayed(const Duration(seconds: 45), () {
      if (_isWalking && mounted) {
        setState(() {
          _currentPromptIndex = (_currentPromptIndex + 1) % _walkingPrompts.length;
        });
        _startPromptCycle();
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
                    _buildWalkingAnimation(),
                    const SizedBox(height: 30),
                    _buildPromptCard(),
                    const SizedBox(height: 30),
                    _buildControls(),
                    const SizedBox(height: 20),
                    if (_isWalking) _buildSessionInfo(),
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
            'Mindful Walk',
            style: AppTypography.sectionHeadingC(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWalkingAnimation() {
    return Container(
      height: 250,
      width: 250,
      decoration: BoxDecoration(
        color: AppColors.card(context),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.softIndigo.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Lottie.network(
          LottieUrls.walking,
          width: 200,
          height: 200,
          fit: BoxFit.contain,
          repeat: true,
          animate: _isWalking,
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 600.ms,
        );
  }

  Widget _buildPromptCard() {
    final prompt = _walkingPrompts[_currentPromptIndex];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: AppColors.softIndigo.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.self_improvement_rounded,
            color: AppColors.softIndigo,
            size: 32,
          ),
          const SizedBox(height: 16),
          Text(
            prompt['title']!,
            style: AppTypography.subtitleC(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            prompt['description']!,
            style: AppTypography.bodyC(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate(key: ValueKey(_currentPromptIndex))
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.2, end: 0, duration: 600.ms);
  }

  Widget _buildControls() {
    return Column(
      children: [
        // Start/Stop button
        GestureDetector(
          onTap: _isWalking ? _stopWalking : _startWalking,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _isWalking
                  ? AppColors.coralDa5e5a
                  : AppColors.softIndigo,
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            ),
            child: Center(
              child: Text(
                _isWalking ? 'End Walk' : 'Start Walking',
                style: AppTypography.buttonText(color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Ambient sound toggle
        GestureDetector(
          onTap: () {
            setState(() => _ambientSoundEnabled = !_ambientSoundEnabled);
            if (_isWalking) {
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
                    ? AppColors.softIndigo
                    : AppColors.dividerColor(context),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _ambientSoundEnabled ? Icons.volume_up : Icons.volume_off,
                  color: _ambientSoundEnabled
                      ? AppColors.softIndigo
                      : AppColors.secondary(context),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Nature Sounds',
                  style: AppTypography.bodyC(context).copyWith(
                    color: _ambientSoundEnabled
                        ? AppColors.softIndigo
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

  Widget _buildSessionInfo() {
    final elapsed = DateTime.now().difference(_sessionStart!);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.softIndigo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            Icons.timer_outlined,
            'Time',
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          ),
          _buildInfoItem(
            Icons.directions_walk_rounded,
            'Progress',
            '${(_currentPromptIndex + 1)}/${_walkingPrompts.length}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.softIndigo, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTypography.captionC(context),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.subtitleC(context).copyWith(
            color: AppColors.softIndigo,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
