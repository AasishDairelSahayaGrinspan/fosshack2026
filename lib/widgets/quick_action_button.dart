import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Quick Action Button — compact card with icon + label for home screen grid.
class QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool highlight;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor,
    this.onTap,
    this.highlight = false,
  });

  @override
  State<QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<QuickActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: AppTheme.tapScaleDuration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: AppTheme.defaultCurve),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.iconColor ?? AppColors.softIndigo;

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(
              color: widget.highlight
                  ? AppColors.amberFdb903
                  : AppColors.dividerColor(context),
              width: widget.highlight ? 1.5 : 0.8,
            ),
            boxShadow: widget.highlight
                ? [
                    BoxShadow(
                      color: AppColors.amberFdb903.withValues(alpha: 0.45),
                      blurRadius: 22,
                      spreadRadius: 1.5,
                    ),
                  ]
                : AppColors.subtleShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                widget.label,
                style: AppTypography.caption(
                  color: AppColors.secondary(context),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
