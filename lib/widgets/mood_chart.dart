import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Minimal weekly mood line chart with smooth animation.
class MoodChart extends StatefulWidget {
  final List<double> moodData; // 7 values, 0.0 to 1.0

  const MoodChart({
    super.key,
    this.moodData = const [0.4, 0.55, 0.6, 0.45, 0.7, 0.8, 0.65],
  });

  @override
  State<MoodChart> createState() => _MoodChartState();
}

class _MoodChartState extends State<MoodChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _lineAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _lineAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.divider, width: 0.8),
        boxShadow: AppColors.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Mood', style: AppTypography.sectionHeading()),
          const SizedBox(height: 4),
          Text('Your emotional rhythm', style: AppTypography.caption()),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: AnimatedBuilder(
              animation: _lineAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(double.infinity, 160),
                  painter: _MoodChartPainter(
                    data: widget.moodData,
                    progress: _lineAnimation.value,
                    lineColor: AppColors.softIndigo,
                    fillColor: AppColors.softIndigo.withValues(alpha: 0.08),
                    dotColor: AppColors.softIndigo,
                    gridColor: AppColors.divider.withValues(alpha: 0.4),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _days
                .map((day) => Text(day, style: AppTypography.caption()))
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the mood line chart.
class _MoodChartPainter extends CustomPainter {
  final List<double> data;
  final double progress;
  final Color lineColor;
  final Color fillColor;
  final Color dotColor;
  final Color gridColor;

  _MoodChartPainter({
    required this.data,
    required this.progress,
    required this.lineColor,
    required this.fillColor,
    required this.dotColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final w = size.width;
    final h = size.height;
    final padding = 8.0;
    final chartH = h - padding * 2;
    final stepX = w / (data.length - 1);

    // Draw subtle horizontal grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (int i = 0; i < 4; i++) {
      final y = padding + chartH * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Build points
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = padding + chartH * (1 - data[i]) * progress;
      points.add(Offset(x, y));
    }

    if (points.length < 2) return;

    // Build smooth path using cubic bezier
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cpx = (p0.dx + p1.dx) / 2;
      path.cubicTo(cpx, p0.dy, cpx, p1.dy, p1.dx, p1.dy);
    }

    // Draw fill gradient below the line
    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, h);
    fillPath.lineTo(points.first.dx, h);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, h), [
        fillColor,
        fillColor.withValues(alpha: 0.0),
      ]);
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // Draw dots
    final dotPaintOuter = Paint()..color = lineColor;
    final dotPaintInner = Paint()..color = Colors.white;
    for (final point in points) {
      canvas.drawCircle(point, 5 * progress, dotPaintOuter);
      canvas.drawCircle(point, 3 * progress, dotPaintInner);
    }
  }

  @override
  bool shouldRepaint(covariant _MoodChartPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.data != data;
}
