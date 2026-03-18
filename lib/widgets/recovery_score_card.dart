import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'frosted_glass_card.dart';

/// Recovery Score Card — circular progress ring with motivational quote.
class RecoveryScoreCard extends StatefulWidget {
  final double score; // 0.0 to 1.0
  final String? quote;

  const RecoveryScoreCard({
    super.key,
    this.score = 0.78,
    this.quote,
  });

  @override
  State<RecoveryScoreCard> createState() => _RecoveryScoreCardState();
}

class _RecoveryScoreCardState extends State<RecoveryScoreCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _countAnimation;

  static const List<String> _quotes = [
    'Even storms run out of rain.',
    'Be gentle with yourself today.',
    'You are more than your worries.',
    'Rest is not giving up.',
    'Healing is not linear.',
  ];

  String get _displayQuote {
    if (widget.quote != null) return widget.quote!;
    final index = DateTime.now().day % _quotes.length;
    return _quotes[index];
  }

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
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(RecoveryScoreCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.score,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _countAnimation = Tween<double>(
        begin: _countAnimation.value,
        end: widget.score * 100,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
    }
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
                      style: AppTypography.sectionHeadingC(context),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You\'re doing beautifully.',
                      style: AppTypography.subtitleC(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return SizedBox(
                    width: 90,
                    height: 90,
                    child: CustomPaint(
                      painter: _ScoreRingPainter(
                        progress: _progressAnimation.value,
                        trackColor: AppColors.dividerColor(context),
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
          // Soft progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _progressAnimation.value,
                  minHeight: 6,
                  backgroundColor: AppColors.dividerColor(context).withValues(alpha: 0.5),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.softIndigo,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          // Inspirational quote — Playfair italic
          Text(
            '"$_displayQuote"',
            style: AppTypography.emotionalTextC(context),
            textAlign: TextAlign.center,
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

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

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
