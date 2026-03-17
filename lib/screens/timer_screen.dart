import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Timer Screen — circular gradient timer with Focus and Relax modes.
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

enum TimerMode { focus, relax }

class _TimerScreenState extends State<TimerScreen>
    with TickerProviderStateMixin {
  TimerMode _mode = TimerMode.focus;
  bool _isRunning = false;
  bool _isComplete = false;

  late AnimationController _timerController;
  late AnimationController _pulseController;

  // Focus: 25 min, Relax: 10 min
  Duration get _totalDuration =>
      _mode == TimerMode.focus
          ? const Duration(minutes: 25)
          : const Duration(minutes: 10);

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: _totalDuration,
    );
    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isRunning = false;
          _isComplete = true;
        });
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _switchMode(TimerMode mode) {
    if (_isRunning) return;
    setState(() {
      _mode = mode;
      _isComplete = false;
      _timerController.duration = _totalDuration;
      _timerController.reset();
    });
  }

  void _toggleTimer() {
    setState(() {
      if (_isComplete) {
        _isComplete = false;
        _timerController.reset();
        return;
      }

      if (_isRunning) {
        _timerController.stop();
        _isRunning = false;
      } else {
        _timerController.forward(from: _timerController.value);
        _isRunning = true;
      }
    });
  }

  void _resetTimer() {
    setState(() {
      _timerController.reset();
      _isRunning = false;
      _isComplete = false;
    });
  }

  String _formatTime(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Color get _modeColor =>
      _mode == TimerMode.focus ? AppColors.softIndigo : AppColors.sageGreen;

  List<Color> get _gradientColors => _mode == TimerMode.focus
      ? [AppColors.cream, AppColors.paleLilac]
      : [AppColors.cream, AppColors.softPeach];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),

              const SizedBox(height: 16),

              // ─── Mode Selector ───
              _buildModeSelector()
                  .animate()
                  .fadeIn(
                    duration: const Duration(milliseconds: 500),
                    curve: AppTheme.gentleCurve,
                  ),

              // ─── Timer Circle ───
              Expanded(
                child: Center(
                  child: _buildTimerCircle(),
                ),
              ),

              // ─── Controls ───
              _buildControls()
                  .animate(delay: const Duration(milliseconds: 200))
                  .fadeIn(
                    duration: const Duration(milliseconds: 500),
                    curve: AppTheme.gentleCurve,
                  ),

              const SizedBox(height: 24),

              // ─── Message ───
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _isComplete
                      ? (_mode == TimerMode.focus
                          ? 'Well done. You showed up.'
                          : 'You gave yourself space.')
                      : (_isRunning
                          ? (_mode == TimerMode.focus
                              ? 'Stay present.'
                              : 'Let everything soften.')
                          : (_mode == TimerMode.focus
                              ? 'Ready when you are.'
                              : 'Take your time.')),
                  key: ValueKey<String>('$_isRunning$_isComplete$_mode'),
                  style: AppTypography.emotionalText(),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
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
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _modeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.secondary(context),
                size: 20,
              ),
            ),
          ),
          Text('Timer', style: AppTypography.uiLabelC(context)),
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.primary(context).withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        ),
        child: Row(
          children: [
            _buildModeTab(TimerMode.focus, 'Focus', Icons.center_focus_strong_outlined),
            _buildModeTab(TimerMode.relax, 'Relax', Icons.spa_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(TimerMode mode, String label, IconData icon) {
    final isSelected = _mode == mode;
    final color = mode == TimerMode.focus ? AppColors.softIndigo : AppColors.sageGreen;

    return Expanded(
      child: GestureDetector(
        onTap: () => _switchMode(mode),
        child: AnimatedContainer(
          duration: AppTheme.fadeInDuration,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.8) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            boxShadow: isSelected ? AppColors.subtleShadow : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? color : AppColors.tertiary(context),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.uiLabel(
                  color: isSelected ? color : AppColors.tertiary(context),
                ).copyWith(
                  fontWeight: isSelected ? FontWeight.w400 : FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerCircle() {
    return AnimatedBuilder(
      animation: _timerController,
      builder: (context, child) {
        final remaining = _totalDuration * (1 - _timerController.value);
        final progress = _timerController.value;

        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulseScale = _isRunning
                ? 1.0 + (_pulseController.value * 0.015)
                : 1.0;

            return Transform.scale(
              scale: pulseScale,
              child: SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow
                    Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _modeColor.withValues(alpha: 0.15),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    // Progress ring
                    CustomPaint(
                      size: const Size(240, 240),
                      painter: _TimerRingPainter(
                        progress: progress,
                        trackColor: AppColors.dividerColor(context).withValues(alpha: 0.3),
                        progressColor: _modeColor,
                        strokeWidth: 5,
                      ),
                    ),
                    // Inner content
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(remaining),
                          style: AppTypography.heroHeading(
                            color: AppColors.primary(context),
                          ).copyWith(
                            fontSize: 44,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _mode == TimerMode.focus ? '25 minutes' : '10 minutes',
                          style: AppTypography.caption(
                            color: _modeColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Reset
          if (_timerController.value > 0)
            GestureDetector(
              onTap: _resetTimer,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary(context).withValues(alpha: 0.05),
                  border: Border.all(
                    color: AppColors.dividerColor(context),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  color: AppColors.secondary(context),
                  size: 22,
                ),
              ),
            ),

          if (_timerController.value > 0) const SizedBox(width: 24),

          // Play/Pause
          GestureDetector(
            onTap: _toggleTimer,
            child: AnimatedContainer(
              duration: AppTheme.fadeInDuration,
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _modeColor.withValues(alpha: 0.15),
                border: Border.all(
                  color: _modeColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _modeColor.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _isComplete
                    ? Icons.refresh_rounded
                    : (_isRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded),
                color: _modeColor,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the timer ring.
class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _TimerRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    this.strokeWidth = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter old) =>
      old.progress != progress;
}
