import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class HabitStreakCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final int streak;
  final List<bool> last14Days; // true = done, false = missed
  final Color? accentColor;
  final String? message;

  const HabitStreakCard({
    super.key,
    required this.icon,
    required this.name,
    required this.streak,
    required this.last14Days,
    this.accentColor,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.softIndigo;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.dividerColor(context), width: 0.8),
        boxShadow: AppColors.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(name, style: AppTypography.uiLabelC(context)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                ),
                child: Text(
                  '$streak day${streak == 1 ? '' : 's'}',
                  style: AppTypography.caption(color: color).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 14-day dot row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(14, (i) {
              final done = i < last14Days.length && last14Days[i];
              return Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? color.withValues(alpha: 0.8) : AppColors.dividerColor(context).withValues(alpha: 0.3),
                ),
                child: done ? Icon(Icons.check_rounded, size: 10, color: Colors.white) : null,
              );
            }),
          ),
          if (message != null) ...[
            const SizedBox(height: 10),
            Text(message!, style: AppTypography.captionC(context)),
          ],
        ],
      ),
    );
  }
}
