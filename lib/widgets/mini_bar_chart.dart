import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class MiniBarChart extends StatelessWidget {
  final List<double> values; // raw values (e.g. hours)
  final double maxValue;
  final List<String>? labels;
  final Color? barColor;
  final String? caption;

  const MiniBarChart({
    super.key,
    required this.values,
    this.maxValue = 10,
    this.labels,
    this.barColor,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final color = barColor ?? AppColors.softIndigo;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.dividerColor(context), width: 0.8),
        boxShadow: AppColors.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 100,
            child: CustomPaint(
              size: const Size(double.infinity, 100),
              painter: _BarPainter(
                values: values,
                maxValue: maxValue,
                barColor: color,
                trackColor: AppColors.dividerColor(
                  context,
                ).withValues(alpha: 0.3),
              ),
            ),
          ),
          if (labels != null && labels!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: labels!
                  .map(
                    (l) => Text(
                      l,
                      style: AppTypography.captionC(
                        context,
                      ).copyWith(fontSize: 10),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (caption != null) ...[
            const SizedBox(height: 8),
            Text(caption!, style: AppTypography.captionC(context)),
          ],
        ],
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;
  final Color barColor;
  final Color trackColor;

  _BarPainter({
    required this.values,
    required this.maxValue,
    required this.barColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final barWidth = (size.width / values.length) * 0.5;
    final gap = (size.width - barWidth * values.length) / (values.length + 1);
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeCap = StrokeCap.round;
    final barPaint = Paint()
      ..color = barColor
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < values.length; i++) {
      final x = gap + i * (barWidth + gap) + barWidth / 2;
      final barH = maxValue > 0
          ? (values[i] / maxValue).clamp(0.0, 1.0) * (size.height - 4)
          : 0.0;
      // Track
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - barWidth / 2, 2, barWidth, size.height - 4),
          Radius.circular(barWidth / 2),
        ),
        trackPaint,
      );
      // Bar
      if (barH > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x - barWidth / 2,
              size.height - 2 - barH,
              barWidth,
              barH,
            ),
            Radius.circular(barWidth / 2),
          ),
          barPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) => old.values != values;
}
