import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Daily Check-in — "What do you need today?" with 4 soft selectable options.
class DailyCheckin extends StatefulWidget {
  final void Function(String need)? onNeedSelected;

  const DailyCheckin({super.key, this.onNeedSelected});

  @override
  State<DailyCheckin> createState() => _DailyCheckinState();
}

class _DailyCheckinState extends State<DailyCheckin> {
  int _selectedIndex = -1;

  static const List<Map<String, dynamic>> _options = [
    {'icon': Icons.center_focus_strong_outlined, 'label': 'Focus', 'color': Color(0xFF9BA4CC)},
    {'icon': Icons.spa_outlined, 'label': 'Calm', 'color': Color(0xFF9CB5A0)},
    {'icon': Icons.cloud_outlined, 'label': 'Release thoughts', 'color': Color(0xFFB8A9C9)},
    {'icon': Icons.nightlight_outlined, 'label': 'Rest', 'color': Color(0xFFE8A598)},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'What do you need today?',
            style: AppTypography.sectionHeadingC(context),
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(_options.length, (index) {
            final isSelected = _selectedIndex == index;
            final option = _options[index];
            final color = option['color'] as Color;

            return GestureDetector(
              onTap: () {
                setState(() => _selectedIndex = index);
                widget.onNeedSelected?.call(option['label'] as String);
              },
              child: AnimatedContainer(
                duration: AppTheme.fadeInDuration,
                curve: AppTheme.defaultCurve,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.12)
                      : AppColors.card(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(
                    color: isSelected
                        ? color.withValues(alpha: 0.5)
                        : AppColors.dividerColor(context),
                    width: isSelected ? 1.5 : 0.8,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                            spreadRadius: 1,
                          ),
                        ]
                      : AppColors.subtleShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: AppTheme.fadeInDuration,
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isSelected ? 0.2 : 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        option['icon'] as IconData,
                        color: isSelected ? color : AppColors.tertiary(context),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      option['label'] as String,
                      style: AppTypography.uiLabel(
                        color: isSelected ? color : AppColors.secondary(context),
                      ).copyWith(
                        fontWeight: isSelected ? FontWeight.w400 : FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(
                  duration: const Duration(milliseconds: 250),
                  curve: AppTheme.gentleCurve,
                );
          }),
        ),
      ],
    );
  }
}
