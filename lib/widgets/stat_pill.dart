import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  const StatPill({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.softIndigo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        border: Border.all(color: c.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c, size: 16),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTypography.uiLabel(
              color: c,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.caption(color: c)),
        ],
      ),
    );
  }
}
