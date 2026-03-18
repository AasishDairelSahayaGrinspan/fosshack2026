import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class CircularProgressCard extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String title;
  final String subtitle;
  final Color? progressColor;

  const CircularProgressCard({
    super.key,
    required this.progress,
    required this.title,
    required this.subtitle,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = progressColor ?? AppColors.softIndigo;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.dividerColor(context), width: 0.8),
        boxShadow: AppColors.subtleShadow,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CustomPaint(
              painter: _ArcPainter(
                progress: progress.clamp(0.0, 1.0),
                trackColor: AppColors.dividerColor(context),
                progressColor: color,
              ),
              child: Center(
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: AppTypography.uiLabel(color: color),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.uiLabelC(context)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.captionC(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _ArcPainter({required this.progress, required this.trackColor, required this.progressColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final track = Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    final prog = Paint()..color = progressColor..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, 2 * pi * progress, false, prog);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) => old.progress != progress;
}
