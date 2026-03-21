import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:just_audio/just_audio.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

/// Grounding exercise types
enum GroundingExercise { 
  breathing446, 
  boxBreathing, 
  breathing478,
  deepBellyBreathing,
  alternateNostril,
  grounding54321, 
  bodyScan 
}

/// Breathing / Grounding Toolkit Screen
/// Supports 4-4-6 breathing, box breathing, 5-4-3-2-1 grounding, and body scan.
class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

enum _Phase { idle, relaxIntro, active }

class _BreathingScreenState extends State<BreathingScreen>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _glowController;
  late AnimationController _colorController;
  late AnimationController _ripple1Controller;
  late AnimationController _ripple2Controller;
  late AnimationController _ripple3Controller;

  // Body scan / 54321 step controller
  late AnimationController _stepProgressController;

  _Phase _phase = _Phase.idle;
  GroundingExercise _selectedExercise = GroundingExercise.breathing446;
  bool _ambientEnabled = true;
  DateTime? _sessionStart;
  String _phaseText = 'Tap to begin';
  String _phaseSubtext = 'Find a comfortable position.';

  AudioPlayer? _audioPlayer;

  // --- Breathing timings ---
  // 4-4-6: 14s total, 4-7-8: 19s total, Box: 16s total
  Duration get _cycleDuration {
    switch (_selectedExercise) {
      case GroundingExercise.breathing446:
        return const Duration(seconds: 14);
      case GroundingExercise.boxBreathing:
        return const Duration(seconds: 16);
      case GroundingExercise.breathing478:
        return const Duration(seconds: 19); // 4s inhale + 7s hold + 8s exhale
      case GroundingExercise.deepBellyBreathing:
        return const Duration(seconds: 12); // 5s inhale + 7s exhale
      case GroundingExercise.alternateNostril:
        return const Duration(seconds: 14); // 4s each side + transition
      default:
        return const Duration(seconds: 14);
    }
  }

  double get _inhaleEnd {
    switch (_selectedExercise) {
      case GroundingExercise.breathing446:
        return 4 / 14;
      case GroundingExercise.boxBreathing:
        return 4 / 16;
      case GroundingExercise.breathing478:
        return 4 / 19;
      case GroundingExercise.deepBellyBreathing:
        return 5 / 12;
      case GroundingExercise.alternateNostril:
        return 4 / 14;
      default:
        return 4 / 14;
    }
  }

  double get _holdEnd {
    switch (_selectedExercise) {
      case GroundingExercise.breathing446:
        return 8 / 14;
      case GroundingExercise.boxBreathing:
        return 8 / 16; // inhale 4 + hold 4
      case GroundingExercise.breathing478:
        return 11 / 19; // inhale 4 + hold 7
      case GroundingExercise.deepBellyBreathing:
        return 5 / 12; // No hold, goes straight to exhale
      case GroundingExercise.alternateNostril:
        return 8 / 14;
      default:
        return 8 / 14;
    }
  }

  double get _exhaleEnd {
    switch (_selectedExercise) {
      case GroundingExercise.boxBreathing:
        return 12 / 16; // inhale 4 + hold 4 + exhale 4
      case GroundingExercise.breathing478:
        return 1.0; // Full cycle completes with exhale
      case GroundingExercise.deepBellyBreathing:
        return 1.0;
      case GroundingExercise.alternateNostril:
        return 1.0;
      default:
        return 1.0;
    }
  }

  // 8 mantra gradient colors
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

  // Zen audio URLs
  static const List<String> _zenAudioUrls = [
    'https://cdn.pixabay.com/audio/2022/02/23/audio_ea70ad08e0.mp3',
    'https://cdn.pixabay.com/audio/2021/11/13/audio_cb57bdd79e.mp3',
    'https://cdn.pixabay.com/audio/2024/11/04/audio_6e69386af8.mp3',
  ];

  // --- 5-4-3-2-1 Grounding ---
  int _groundingStepIndex = 0;
  static const List<_GroundingStep> _groundingSteps = [
    _GroundingStep(5, 'things you can see', [
      Color(0xFF6B9BD2),
      Color(0xFF4A7FB5),
    ]),
    _GroundingStep(4, 'things you can feel', [
      Color(0xFF7BC67E),
      Color(0xFF5AAF5D),
    ]),
    _GroundingStep(3, 'things you can hear', [
      Color(0xFFE2814D),
      Color(0xFFD06B38),
    ]),
    _GroundingStep(2, 'things you can smell', [
      Color(0xFFDA5E5A),
      Color(0xFFC04844),
    ]),
    _GroundingStep(1, 'thing you can taste', [
      Color(0xFFFDB903),
      Color(0xFFE5A600),
    ]),
  ];

  // --- Body Scan ---
  int _bodyScanIndex = 0;
  static const List<String> _bodyParts = [
    'Feet',
    'Legs',
    'Hips',
    'Stomach',
    'Chest',
    'Hands',
    'Arms',
    'Shoulders',
    'Neck',
    'Face',
    'Whole Body',
  ];
  static const _bodyScanHoldDuration = Duration(seconds: 8);

  // Exercise labels for chip bar
  static const Map<GroundingExercise, String> _exerciseLabels = {
    GroundingExercise.breathing446: '4-4-6 Breathing',
    GroundingExercise.boxBreathing: 'Box Breathing',
    GroundingExercise.breathing478: '4-7-8 Breathing',
    GroundingExercise.deepBellyBreathing: 'Deep Belly',
    GroundingExercise.alternateNostril: 'Alternate Nostril',
    GroundingExercise.grounding54321: '5-4-3-2-1',
    GroundingExercise.bodyScan: 'Body Scan',
  };

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

    _colorController =
        AnimationController(vsync: this, duration: const Duration(seconds: 15))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              setState(() {
                _colorIndex = (_colorIndex + 1) % _mantraColors.length;
              });
              _colorController.forward(from: 0);
            }
          });

    _ripple1Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _ripple2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _ripple3Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _stepProgressController = AnimationController(
      vsync: this,
      duration: _bodyScanHoldDuration,
    );

    _breathController.addListener(_updatePhaseText);
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setLoopMode(LoopMode.all);
      await _audioPlayer!.setVolume(0.3);
      for (final url in _zenAudioUrls) {
        try {
          await _audioPlayer!.setUrl(url);
          break;
        } catch (_) {
          continue;
        }
      }
    } catch (_) {
      _audioPlayer = null;
    }
  }

  void _startRipples() {
    _ripple1Controller.repeat();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _ripple2Controller.repeat();
    });
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) _ripple3Controller.repeat();
    });
  }

  void _stopRipples() {
    _ripple1Controller.stop();
    _ripple1Controller.reset();
    _ripple2Controller.stop();
    _ripple2Controller.reset();
    _ripple3Controller.stop();
    _ripple3Controller.reset();
  }

  void _updatePhaseText() {
    if (_phase != _Phase.active) return;
    if (_selectedExercise != GroundingExercise.breathing446 &&
        _selectedExercise != GroundingExercise.boxBreathing) {
      return;
    }

    final progress = _breathController.value;
    String newPhase;
    String newSubtext;

    if (progress < _inhaleEnd) {
      newPhase = 'Inhale';
      newSubtext = 'Breathe in slowly...';
    } else if (progress < _holdEnd) {
      newPhase = 'Hold';
      newSubtext = 'Gently hold...';
    } else if (_selectedExercise == GroundingExercise.boxBreathing &&
        progress < _exhaleEnd) {
      newPhase = 'Exhale';
      newSubtext = 'Let it all go...';
    } else if (_selectedExercise == GroundingExercise.boxBreathing) {
      newPhase = 'Hold';
      newSubtext = 'Hold gently...';
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

  Future<void> _startSession() async {
    if (_phase != _Phase.idle) return;

    setState(() {
      _phase = _Phase.relaxIntro;
      _phaseText = 'Sit relaxed';
      _phaseSubtext = 'Find a quiet spot and sit comfortably.';
    });

    _startRipples();

    if (_ambientEnabled && _audioPlayer != null) {
      try {
        await _audioPlayer!.seek(Duration.zero);
        _audioPlayer!.play();
      } catch (_) {}
    }

    await Future.delayed(const Duration(seconds: 5));
    if (!mounted || _phase != _Phase.relaxIntro) return;

    setState(() {
      _phaseText = 'Relax';
      _phaseSubtext = 'Close your eyes. Let go of all tension...';
    });

    await Future.delayed(const Duration(seconds: 5));
    if (!mounted || _phase != _Phase.relaxIntro) return;

    setState(() {
      _phaseText = 'Ready';
      _phaseSubtext = "Let's begin.";
    });

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted || _phase != _Phase.relaxIntro) return;

    setState(() {
      _phase = _Phase.active;
      _sessionStart = DateTime.now();
    });

    _colorController.forward(from: 0);

    switch (_selectedExercise) {
      case GroundingExercise.breathing446:
      case GroundingExercise.boxBreathing:
      case GroundingExercise.breathing478:
      case GroundingExercise.deepBellyBreathing:
      case GroundingExercise.alternateNostril:
        _breathController.duration = _cycleDuration;
        setState(() {
          _phaseText = 'Inhale';
          _phaseSubtext = 'Breathe in slowly...';
        });
        _breathController.repeat();
        break;
      case GroundingExercise.grounding54321:
        _groundingStepIndex = 0;
        _updateGroundingText();
        break;
      case GroundingExercise.bodyScan:
        _bodyScanIndex = 0;
        _runBodyScan();
        break;
    }
  }

  void _updateGroundingText() {
    if (_groundingStepIndex >= _groundingSteps.length) return;
    final step = _groundingSteps[_groundingStepIndex];
    setState(() {
      _phaseText = '${step.count}';
      _phaseSubtext = 'Name ${step.count} ${step.label}';
    });
  }

  void _advanceGroundingStep() {
    if (_phase != _Phase.active) return;
    if (_selectedExercise != GroundingExercise.grounding54321) return;

    if (_groundingStepIndex < _groundingSteps.length - 1) {
      setState(() => _groundingStepIndex++);
      _updateGroundingText();
    } else {
      // Complete
      setState(() {
        _phaseText = 'Well done';
        _phaseSubtext = 'You are grounded and present.';
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _stopSession();
      });
    }
  }

  Future<void> _runBodyScan() async {
    while (mounted &&
        _phase == _Phase.active &&
        _bodyScanIndex < _bodyParts.length) {
      final part = _bodyParts[_bodyScanIndex];
      setState(() {
        _phaseText = part;
        _phaseSubtext = _bodyScanIndex == _bodyParts.length - 1
            ? 'Feel your whole body relax...'
            : 'Relax your ${part.toLowerCase()}...';
      });

      _stepProgressController.duration = _bodyScanHoldDuration;
      _stepProgressController.forward(from: 0);

      await Future.delayed(_bodyScanHoldDuration);
      if (!mounted || _phase != _Phase.active) return;

      _bodyScanIndex++;
    }

    if (mounted && _phase == _Phase.active) {
      setState(() {
        _phaseText = 'Complete';
        _phaseSubtext = 'Your body is at ease.';
      });
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) _stopSession();
    }
  }

  void _stopSession() {
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
    _stepProgressController.stop();
    _stepProgressController.reset();
    _stopRipples();
    _audioPlayer?.pause();

    setState(() {
      _phase = _Phase.idle;
      _phaseText = 'Tap to begin';
      _phaseSubtext = 'Find a comfortable position.';
      _groundingStepIndex = 0;
      _bodyScanIndex = 0;
    });
  }

  void _onCircleTap() {
    if (_phase == _Phase.idle) {
      _startSession();
    } else if (_selectedExercise == GroundingExercise.grounding54321 &&
        _phase == _Phase.active) {
      _advanceGroundingStep();
    } else {
      _stopSession();
    }
  }

  void _toggleAmbient() {
    setState(() => _ambientEnabled = !_ambientEnabled);
    if (_ambientEnabled && _phase != _Phase.idle) {
      _audioPlayer?.play();
    } else {
      _audioPlayer?.pause();
    }
  }

  void _selectExercise(GroundingExercise exercise) {
    if (_phase != _Phase.idle) _stopSession();
    setState(() => _selectedExercise = exercise);
  }

  @override
  void dispose() {
    _breathController.dispose();
    _glowController.dispose();
    _colorController.dispose();
    _ripple1Controller.dispose();
    _ripple2Controller.dispose();
    _ripple3Controller.dispose();
    _stepProgressController.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  double _circleScale(double progress) {
    if (_selectedExercise == GroundingExercise.boxBreathing) {
      if (progress < _inhaleEnd) {
        return progress / _inhaleEnd;
      } else if (progress < _holdEnd) {
        return 1.0;
      } else if (progress < _exhaleEnd) {
        return 1.0 - ((progress - _holdEnd) / (_exhaleEnd - _holdEnd));
      } else {
        return 0.0;
      }
    }
    // 4-4-6
    if (progress < _inhaleEnd) {
      return progress / _inhaleEnd;
    } else if (progress < _holdEnd) {
      return 1.0;
    } else {
      return 1.0 - ((progress - _holdEnd) / (1 - _holdEnd));
    }
  }

  List<Color> get _activeGradientColors {
    if (_selectedExercise == GroundingExercise.grounding54321 &&
        _phase == _Phase.active &&
        _groundingStepIndex < _groundingSteps.length) {
      return _groundingSteps[_groundingStepIndex].colors;
    }
    return [AppColors.warmLavender, AppColors.softPeach];
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

          final useMantra =
              _phase != _Phase.idle &&
              (_selectedExercise == GroundingExercise.breathing446 ||
                  _selectedExercise == GroundingExercise.boxBreathing);

          final gradientColors = useMantra
              ? [c1, c2]
              : _phase == _Phase.active &&
                    _selectedExercise == GroundingExercise.grounding54321
              ? _activeGradientColors
              : _phase != _Phase.idle
              ? [c1, c2]
              : [AppColors.warmLavender, AppColors.softPeach];

          return AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildExerciseSelector(),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _onCircleTap,
                    child:
                        _selectedExercise == GroundingExercise.bodyScan &&
                            _phase == _Phase.active
                        ? _buildBodyScanVisual()
                        : _buildBreathCircleWithRipples(),
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
                  key: ValueKey<String>('$_phaseText$_phaseSubtext'),
                  children: [
                    Text(
                      _phaseText,
                      style: AppTypography.heroHeading(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _phaseSubtext,
                      style: AppTypography.subtitle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    if (_selectedExercise == GroundingExercise.grounding54321 &&
                        _phase == _Phase.active)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Tap to continue',
                          style: AppTypography.caption(color: Colors.white54),
                        ),
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

  Widget _buildExerciseSelector() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: GroundingExercise.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final exercise = GroundingExercise.values[i];
          final isSelected = exercise == _selectedExercise;
          return GestureDetector(
            onTap: () => _selectExercise(exercise),
            child: AnimatedContainer(
              duration: AppTheme.fadeInDuration,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: Text(
                  _exerciseLabels[exercise]!,
                  style: AppTypography.caption(
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 500),
      curve: AppTheme.gentleCurve,
    );
  }

  Widget _buildBreathCircleWithRipples() {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildRipple(_ripple1Controller),
          _buildRipple(_ripple2Controller),
          _buildRipple(_ripple3Controller),
          _buildBreathCircle(),
        ],
      ),
    );
  }

  Widget _buildRipple(AnimationController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = controller.value;
        final size = 140.0 + (value * 160.0);
        final opacity = (1.0 - value) * 0.25;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: opacity),
              width: 1.5,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBreathCircle() {
    return AnimatedBuilder(
      animation: _breathController,
      builder: (context, child) {
        final scale =
            _phase == _Phase.active &&
                (_selectedExercise == GroundingExercise.breathing446 ||
                    _selectedExercise == GroundingExercise.boxBreathing)
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
                    color: AppColors.softIndigo.withValues(alpha: glowOpacity),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                  BoxShadow(
                    color: AppColors.paleLilac.withValues(
                      alpha: glowOpacity * 0.8,
                    ),
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
                child:
                    _selectedExercise == GroundingExercise.grounding54321 &&
                        _phase == _Phase.active &&
                        _groundingStepIndex < _groundingSteps.length
                    ? Center(
                        child: Text(
                          '${_groundingSteps[_groundingStepIndex].count}',
                          style: AppTypography.heroHeading(
                            color: Colors.white,
                          ).copyWith(fontSize: 64),
                        ),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBodyScanVisual() {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildRipple(_ripple1Controller),
          _buildRipple(_ripple2Controller),
          _buildRipple(_ripple3Controller),
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              final glowOpacity = 0.15 + (_glowController.value * 0.15);
              return Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.softIndigo.withValues(
                        alpha: glowOpacity,
                      ),
                      blurRadius: 60,
                      spreadRadius: 20,
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.self_improvement_rounded,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      // Progress indicator
                      SizedBox(
                        width: 100,
                        child: AnimatedBuilder(
                          animation: _stepProgressController,
                          builder: (context, child) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _stepProgressController.value,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white70,
                                ),
                                minHeight: 4,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              if (_phase != _Phase.idle) _stopSession();
              Navigator.of(context).pop();
            },
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
          Text(
            'Grounding Toolkit',
            style: AppTypography.uiLabel(color: Colors.white),
          ),
          const SizedBox(width: 42),
        ],
      ),
    ).animate().fadeIn(
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
            onTap: _onCircleTap,
            child: AnimatedContainer(
              duration: AppTheme.fadeInDuration,
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _phase != _Phase.idle
                    ? AppColors.warmCoral.withValues(alpha: 0.15)
                    : AppColors.softIndigo.withValues(alpha: 0.15),
                border: Border.all(
                  color: _phase != _Phase.idle
                      ? AppColors.warmCoral.withValues(alpha: 0.3)
                      : AppColors.softIndigo.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                _phase != _Phase.idle
                    ? (_selectedExercise == GroundingExercise.grounding54321
                          ? Icons.arrow_forward_rounded
                          : Icons.pause_rounded)
                    : Icons.play_arrow_rounded,
                color: _phase != _Phase.idle
                    ? AppColors.warmCoral
                    : AppColors.softIndigo,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Ambient sound toggle
          GestureDetector(
            onTap: _toggleAmbient,
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
          // Stop button (shown during active session for grounding/bodyscan)
          if (_phase != _Phase.idle &&
              (_selectedExercise == GroundingExercise.grounding54321 ||
                  _selectedExercise == GroundingExercise.bodyScan)) ...[
            const SizedBox(width: 24),
            GestureDetector(
              onTap: _stopSession,
              child: AnimatedContainer(
                duration: AppTheme.fadeInDuration,
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.warmCoral.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.warmCoral.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.stop_rounded,
                  color: AppColors.warmCoral,
                  size: 28,
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 300),
      duration: const Duration(milliseconds: 500),
      curve: AppTheme.gentleCurve,
    );
  }
}

class _GroundingStep {
  final int count;
  final String label;
  final List<Color> colors;

  const _GroundingStep(this.count, this.label, this.colors);
}
