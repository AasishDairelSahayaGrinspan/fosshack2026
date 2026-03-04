import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'frosted_glass_card.dart';

/// Recovery Score Card — large card with animated circular percentage ring.
class RecoveryScoreCard extends StatefulWidget {
  final double score; // 0.0 to 1.0

  const RecoveryScoreCard({super.key, this.score = 0.78});

  @override
  State<RecoveryScoreCard> createState() => _RecoveryScoreCardState();
}

class _RecoveryScoreCardState extends State<RecoveryScoreCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _countAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.score,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _countAnimation = Tween<double>(
      begin: 0,
      end: widget.score * 100,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    // Start animation after a brief delay for visual effect
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FrostedGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recovery Score',
                      style: AppTypography.sectionHeading(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You\'re doing beautifully.',
                      style: AppTypography.subtitle(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Animated Circle
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return SizedBox(
                    width: 90,
                    height: 90,
                    child: CustomPaint(
                      painter: _ScoreRingPainter(
                        progress: _progressAnimation.value,
                        trackColor: AppColors.divider,
                        progressColor: AppColors.softIndigo,
                      ),
                      child: Center(
                        child: Text(
                          '${_countAnimation.value.toInt()}%',
                          style: AppTypography.sectionHeading(
                            color: AppColors.softIndigo,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Soft motivational bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _progressAnimation.value,
                  minHeight: 6,
                  backgroundColor: AppColors.divider.withValues(alpha: 0.5),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.softIndigo,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the circular score ring
class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _ScoreRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
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
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
