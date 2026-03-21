import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Timer Screen with focus/relax modes and a scrollable duration picker.
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
  int _focusMinutes = 25;
  int _relaxMinutes = 10;

  late AnimationController _timerController;
  late AnimationController _pulseController;
  late FixedExtentScrollController _minuteWheelController;

  int get _selectedMinutes =>
      _mode == TimerMode.focus ? _focusMinutes : _relaxMinutes;

  Duration get _totalDuration => Duration(minutes: _selectedMinutes);

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

    _minuteWheelController = FixedExtentScrollController(
      initialItem: _selectedMinutes - 1,
    );
  }

  @override
  void dispose() {
    _timerController.dispose();
    _pulseController.dispose();
    _minuteWheelController.dispose();
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
    _syncMinuteWheel();
  }

  void _syncMinuteWheel() {
    if (!_minuteWheelController.hasClients) return;
    _minuteWheelController.animateToItem(
      _selectedMinutes - 1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _onMinuteChanged(int index) {
    if (_isRunning) return;
    final minutes = index + 1;
    setState(() {
      if (_mode == TimerMode.focus) {
        _focusMinutes = minutes;
      } else {
        _relaxMinutes = minutes;
      }
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

              _buildModeSelector().animate().fadeIn(
                duration: const Duration(milliseconds: 500),
                curve: AppTheme.gentleCurve,
              ),

              const SizedBox(height: 12),

              _buildDurationPicker()
                  .animate(delay: const Duration(milliseconds: 100))
                  .fadeIn(
                    duration: const Duration(milliseconds: 500),
                    curve: AppTheme.gentleCurve,
                  ),

              const SizedBox(height: 10),

              Expanded(child: Center(child: _buildTimerCircle())),

              _buildControls()
                  .animate(delay: const Duration(milliseconds: 200))
                  .fadeIn(
                    duration: const Duration(milliseconds: 500),
                    curve: AppTheme.gentleCurve,
                  ),

              const SizedBox(height: 24),

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
            _buildModeTab(
              TimerMode.focus,
              'Focus',
              Icons.center_focus_strong_outlined,
            ),
            _buildModeTab(TimerMode.relax, 'Relax', Icons.spa_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(TimerMode mode, String label, IconData icon) {
    final isSelected = _mode == mode;
    final color = mode == TimerMode.focus
        ? AppColors.softIndigo
        : AppColors.sageGreen;

    return Expanded(
      child: GestureDetector(
        onTap: () => _switchMode(mode),
        child: AnimatedContainer(
          duration: AppTheme.fadeInDuration,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.transparent,
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
                style:
                    AppTypography.uiLabel(
                      color: isSelected ? color : AppColors.tertiary(context),
                    ).copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w400
                          : FontWeight.w300,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationPicker() {
    return Column(
      children: [
        Text(
          'Session length',
          style: AppTypography.caption(color: AppColors.tertiary(context)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 112,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 132,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _modeColor.withValues(alpha: 0.25)),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: _minuteWheelController,
                itemExtent: 34,
                diameterRatio: 1.25,
                perspective: 0.004,
                squeeze: 1.08,
                physics: _isRunning
                    ? const NeverScrollableScrollPhysics()
                    : const FixedExtentScrollPhysics(),
                onSelectedItemChanged: _onMinuteChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 60,
                  builder: (context, i) {
                    if (i < 0 || i >= 60) return null;
                    final isSelected = i + 1 == _selectedMinutes;
                    return Center(
                      child: Text(
                        '${i + 1} min',
                        style:
                            AppTypography.uiLabel(
                              color: isSelected
                                  ? _modeColor
                                  : AppColors.tertiary(context),
                            ).copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.w300,
                            ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
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
                    CustomPaint(
                      size: const Size(240, 240),
                      painter: _TimerRingPainter(
                        progress: progress,
                        trackColor: AppColors.dividerColor(
                          context,
                        ).withValues(alpha: 0.3),
                        progressColor: _modeColor,
                        strokeWidth: 5,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(remaining),
                          style:
                              AppTypography.heroHeading(
                                color: AppColors.primary(context),
                              ).copyWith(
                                fontSize: 44,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 2,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_selectedMinutes minutes',
                          style: AppTypography.caption(color: _modeColor),
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

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

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
