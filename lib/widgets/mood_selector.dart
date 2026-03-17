import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

/// Mood Selector — 5 emotional states with glow + scale animation.
class MoodSelector extends StatefulWidget {
  final ValueChanged<double>? onMoodSaved;

  const MoodSelector({super.key, this.onMoodSaved});

  @override
  State<MoodSelector> createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector> {
  int _selectedIndex = -1;

  // Map mood index to a 0-1 score: Calm=0.9, Okay=0.7, Low=0.4, Anxious=0.25, Overwhelmed=0.1
  static const List<double> _moodScores = [0.9, 0.7, 0.4, 0.25, 0.1];

  Future<void> _saveMood(int index) async {
    final user = AuthService().currentUser;
    if (user == null) return;
    try {
      await DatabaseService().saveMoodEntry(
        userId: user.$id,
        mood: _moodScores[index],
        emoji: _moods[index]['emoji'] as String,
      );
      // Also update streak on mood selection (counts as daily check-in)
      await DatabaseService().updateStreak(user.$id);
      widget.onMoodSaved?.call(_moodScores[index]);
    } catch (e, st) {
      developer.log('Failed to save mood', name: 'MoodSelector', error: e, stackTrace: st);
    }
  }

  static const List<Map<String, dynamic>> _moods = [
    {'emoji': '😌', 'label': 'Calm', 'color': AppColors.sageGreen},
    {'emoji': '🙂', 'label': 'Okay', 'color': AppColors.softIndigo},
    {'emoji': '😔', 'label': 'Low', 'color': AppColors.orangeE2814d},
    {'emoji': '😰', 'label': 'Anxious', 'color': AppColors.warmCoral},
    {'emoji': '😣', 'label': 'Overwhelmed', 'color': AppColors.coralDa5e5a},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Text(
            'How is your mind today?',
            style: AppTypography.sectionHeadingC(context),
          ),
        ),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _moods.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final isSelected = _selectedIndex == index;
              final moodColor = _moods[index]['color'] as Color;
              return GestureDetector(
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      _saveMood(index);
                    },
                    child: AnimatedContainer(
                      duration: AppTheme.fadeInDuration,
                      curve: AppTheme.defaultCurve,
                      width: 76,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? moodColor.withValues(alpha: 0.12)
                            : AppColors.card(context),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusCard,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? moodColor.withValues(alpha: 0.5)
                              : AppColors.dividerColor(context),
                          width: isSelected ? 1.8 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: moodColor.withValues(alpha: 0.25),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 2,
                                ),
                              ]
                            : AppColors.subtleShadow,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            scale: isSelected ? 1.3 : 1.0,
                            duration: AppTheme.fadeInDuration,
                            curve: AppTheme.defaultCurve,
                            child: Text(
                              _moods[index]['emoji'] as String,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _moods[index]['label'] as String,
                            style: AppTypography.caption(
                              color: isSelected
                                  ? moodColor
                                  : AppColors.tertiary(context),
                            ).copyWith(
                              fontWeight:
                                  isSelected ? FontWeight.w500 : FontWeight.w300,
                            ),
                            textAlign: TextAlign.center,
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
            },
          ),
        ),
      ],
    );
  }
}
