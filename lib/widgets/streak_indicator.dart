import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Streak Indicator — small card with flame icon and streak count.
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.divider, width: 0.8),
        boxShadow: AppColors.subtleShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated flame
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.warmCoral.withValues(alpha: _glowAnimation.value),
                    const Color(
                      0xFFFFB347,
                    ).withValues(alpha: _glowAnimation.value),
                  ],
                ).createShader(bounds),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  size: 26,
                  color: Colors.white,
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.streakDays} day streak',
                style: AppTypography.buttonText(),
              ),
              Text('Keep it going!', style: AppTypography.caption()),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.sageGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            ),
            child: Text(
              '🌿 Active',
              style: AppTypography.caption(color: AppColors.sageGreen),
            ),
          ),
        ],
      ),
    );
  }
}
