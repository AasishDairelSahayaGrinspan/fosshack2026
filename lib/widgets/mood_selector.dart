import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Daily Mood Selector — horizontal scrollable emoji mood cards.
class MoodSelector extends StatefulWidget {
  const MoodSelector({super.key});

  @override
  State<MoodSelector> createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector> {
  int _selectedIndex = -1;

  static const List<Map<String, String>> _moods = [
    {'emoji': '😔', 'label': 'Low'},
    {'emoji': '😕', 'label': 'Meh'},
    {'emoji': '😐', 'label': 'Okay'},
    {'emoji': '🙂', 'label': 'Good'},
    {'emoji': '😊', 'label': 'Great'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Text(
            'How are you feeling?',
            style: AppTypography.sectionHeading(),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _moods.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final isSelected = _selectedIndex == index;
              return GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: AnimatedContainer(
                      duration: AppTheme.fadeInDuration,
                      curve: AppTheme.defaultCurve,
                      width: 72,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.softIndigo.withValues(alpha: 0.12)
                            : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusCard,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.softIndigo.withValues(alpha: 0.5)
                              : AppColors.divider,
                          width: isSelected ? 1.8 : 1,
                        ),
                        boxShadow: isSelected
                            ? AppColors.softShadow
                            : AppColors.subtleShadow,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            scale: isSelected ? 1.2 : 1.0,
                            duration: AppTheme.fadeInDuration,
                            curve: AppTheme.defaultCurve,
                            child: Text(
                              _moods[index]['emoji']!,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _moods[index]['label']!,
                            style: AppTypography.caption(
                              color: isSelected
                                  ? AppColors.softIndigo
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(
                    duration: Duration(milliseconds: 300 + index * 80),
                    curve: AppTheme.gentleCurve,
                  )
                  .slideX(
                    begin: 0.15,
                    end: 0,
                    duration: Duration(milliseconds: 300 + index * 80),
                    curve: AppTheme.gentleCurve,
                  );
            },
          ),
        ),
      ],
    );
  }
}
