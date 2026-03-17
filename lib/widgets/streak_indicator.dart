import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Streak Indicator — animated flame with "X days of showing up."
class StreakIndicator extends StatefulWidget {
  final int streakDays;

  const StreakIndicator({super.key, this.streakDays = 5});

  @override
  State<StreakIndicator> createState() => _StreakIndicatorState();
}

class _StreakIndicatorState extends State<StreakIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: AppTheme.defaultCurve),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.dividerColor(context), width: 0.8),
        boxShadow: AppColors.subtleShadow,
      ),
      child: Row(
        children: [
          // Animated flame
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.warmCoral.withValues(
                    alpha: 0.08 + (_glowAnimation.value * 0.07),
                  ),
                ),
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.warmCoral
                          .withValues(alpha: _glowAnimation.value),
                      AppColors.orangeE2814d
                          .withValues(alpha: _glowAnimation.value),
                    ],
                  ).createShader(bounds),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.streakDays} days of showing up.',
                  style: AppTypography.buttonTextC(context),
                ),
                const SizedBox(height: 2),
                Text(
                  'You\'re building something beautiful.',
                  style: AppTypography.captionC(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
