import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Community Activity Card — subtle invite to community engagement.
/// "Someone shared a story today." with a "Visit Community" button.
class CommunityActivityCard extends StatelessWidget {
  final VoidCallback? onTap;

  const CommunityActivityCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.dividerColor(context), width: 0.8),
        boxShadow: AppColors.subtleShadow,
      ),
      child: Row(
        children: [
          // Soft icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.paleLilac.withValues(alpha: 0.3),
            ),
            child: Icon(
              Icons.people_outline_rounded,
              color: AppColors.softIndigo.withValues(alpha: 0.7),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Someone shared a story today.',
                  style: AppTypography.bodyC(context),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    'Visit Community',
                    style: AppTypography.caption(color: AppColors.softIndigo)
                        .copyWith(
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.softIndigo.withValues(
                            alpha: 0.4,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
