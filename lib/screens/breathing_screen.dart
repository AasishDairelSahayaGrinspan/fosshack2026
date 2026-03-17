import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

/// Breathing Screen — 8 mantra gradient colors, 4/4/6 breathing cycle,
/// expanding circle, zen music toggle.
class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _glowController;
  late AnimationController _colorController;
  bool _isActive = false;
  bool _ambientEnabled = true;
  DateTime? _sessionStart;
  String _phaseText = 'Tap to begin';
  String _phaseSubtext = 'Find a comfortable position.';

  // 4s inhale + 4s hold + 6s exhale = 14s total
  static const _cycleDuration = Duration(seconds: 14);
  static const double _inhaleEnd = 4 / 14;
  static const double _holdEnd = 8 / 14;

  // 8 mantra gradient colors mapped to the global palette
  static const List<List<Color>> _mantraColors = [
    [AppColors.ink304057, AppColors.coralDa5e5a],
    [AppColors.coralDa5e5a, AppColors.orangeE2814d],
    [AppColors.orangeE2814d, AppColors.amberFdb903],
    [AppColors.amberFdb903, AppColors.coralDa5e5a],
    [AppColors.ink304057, AppColors.orangeE2814d],
    [AppColors.ink304057, AppColors.amberFdb903],
    [AppColors.coralDa5e5a, AppColors.amberFdb903],
    [AppColors.white, AppColors.lightBlush],
  ];

  int _colorIndex = 0;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: _cycleDuration,
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Color transition: 15 seconds per color shift
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _colorIndex = (_colorIndex + 1) % _mantraColors.length;
          });
          _colorController.forward(from: 0);
        }
      });

    _breathController.addListener(_updatePhaseText);
  }

  void _updatePhaseText() {
    if (!_isActive) return;
    final progress = _breathController.value;
    String newPhase;
    String newSubtext;

    if (progress < _inhaleEnd) {
      newPhase = 'Inhale';
      newSubtext = 'Breathe in slowly...';
    } else if (progress < _holdEnd) {
      newPhase = 'Hold';
      newSubtext = 'Gently hold...';
    } else {
      newPhase = 'Exhale';
      newSubtext = 'Let it all go...';
    }

    if (newPhase != _phaseText) {
      setState(() {
        _phaseText = newPhase;
        _phaseSubtext = newSubtext;
      });
    }
  }

  void _toggleBreathing() {
    setState(() {
      _isActive = !_isActive;
      if (_isActive) {
        _sessionStart = DateTime.now();
        _breathController.repeat();
        _colorController.forward(from: 0);
        _phaseText = 'Inhale';
        _phaseSubtext = 'Breathe in slowly...';
      } else {
        // Save completed session
        if (_sessionStart != null) {
          final duration = DateTime.now().difference(_sessionStart!).inSeconds;
          final user = AuthService().currentUser;
          if (user != null && duration > 2) {
            DatabaseService().saveBreathingSession(
              userId: user.$id,
              durationSeconds: duration,
              ambientEnabled: _ambientEnabled,
            );
          }
          _sessionStart = null;
        }
        _breathController.stop();
        _breathController.reset();
        _colorController.stop();
        _colorController.reset();
        _phaseText = 'Tap to begin';
        _phaseSubtext = 'Find a comfortable position.';
      }
    });
  }

  @override
  void dispose() {
    _breathController.dispose();
    _glowController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  double _circleScale(double progress) {
    if (progress < _inhaleEnd) {
      return progress / _inhaleEnd; // 0 → 1
    } else if (progress < _holdEnd) {
      return 1.0; // hold
    } else {
      return 1.0 - ((progress - _holdEnd) / (1 - _holdEnd)); // 1 → 0
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextIndex = (_colorIndex + 1) % _mantraColors.length;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _colorController,
        builder: (context, child) {
          final t = _colorController.value;
          final c1 = Color.lerp(
            _mantraColors[_colorIndex][0],
            _mantraColors[nextIndex][0],
            t,
          )!;
          final c2 = Color.lerp(
            _mantraColors[_colorIndex][1],
            _mantraColors[nextIndex][1],
            t,
          )!;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isActive ? [c1, c2] : [
                  AppColors.warmLavender,
                  AppColors.softPeach,
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _toggleBreathing,
                    child: _buildBreathCircle(),
                  ),
                ),
              ),
              // Phase text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Column(
                  key: ValueKey<String>(_phaseText),
                  children: [
                    Text(
                      _phaseText,
                      style: AppTypography.heroHeading(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _phaseSubtext,
                      style: AppTypography.subtitle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildControls(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreathCircle() {
    return AnimatedBuilder(
      animation: _breathController,
      builder: (context, child) {
        final scale = _isActive
            ? 0.5 + (_circleScale(_breathController.value) * 0.5)
            : 0.5;

        return AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            final glowOpacity = 0.15 + (_glowController.value * 0.15);

            return Container(
              width: 220 * scale + 60,
              height: 220 * scale + 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.softIndigo
                        .withValues(alpha: glowOpacity),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                  BoxShadow(
                    color: AppColors.paleLilac
                        .withValues(alpha: glowOpacity * 0.8),
                    blurRadius: 80,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.softIndigo.withValues(alpha: 0.3),
                      AppColors.paleLilac.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ),
          Text('Breathing', style: AppTypography.uiLabel(color: Colors.white)),
          const SizedBox(width: 42),
        ],
      ),
    )
        .animate()
        .fadeIn(
          duration: const Duration(milliseconds: 500),
          curve: AppTheme.gentleCurve,
        );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Play/Pause
          GestureDetector(
            onTap: _toggleBreathing,
            child: AnimatedContainer(
              duration: AppTheme.fadeInDuration,
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isActive
                    ? AppColors.warmCoral.withValues(alpha: 0.15)
                    : AppColors.softIndigo.withValues(alpha: 0.15),
                border: Border.all(
                  color: _isActive
                      ? AppColors.warmCoral.withValues(alpha: 0.3)
                      : AppColors.softIndigo.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                _isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: _isActive ? AppColors.warmCoral : AppColors.softIndigo,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Ambient sound toggle
          GestureDetector(
            onTap: () => setState(() => _ambientEnabled = !_ambientEnabled),
            child: AnimatedContainer(
              duration: AppTheme.fadeInDuration,
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _ambientEnabled
                    ? AppColors.sageGreen.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.1),
                border: Border.all(
                  color: _ambientEnabled
                      ? AppColors.sageGreen.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _ambientEnabled
                        ? Icons.music_note_rounded
                        : Icons.music_off_rounded,
                    color: _ambientEnabled
                        ? AppColors.sageGreen
                        : Colors.white54,
                    size: 20,
                  ),
                  Text(
                    'Zen',
                    style: AppTypography.caption(
                      color: _ambientEnabled
                          ? AppColors.sageGreen
                          : Colors.white54,
                    ).copyWith(fontSize: 8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          delay: const Duration(milliseconds: 300),
          duration: const Duration(milliseconds: 500),
          curve: AppTheme.gentleCurve,
        );
  }
}
