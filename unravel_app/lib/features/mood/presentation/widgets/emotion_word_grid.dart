import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/circumplex_data.dart';
import '../../domain/providers/mood_provider.dart';

class EmotionWordGrid extends ConsumerWidget {
  final MoodQuadrant quadrant;
  final void Function(EmotionWord word) onEmotionSelected;

  const EmotionWordGrid({
    super.key,
    required this.quadrant,
    required this.onEmotionSelected,
  });

  Color _quadrantColor(MoodQuadrant q) {
    switch (q) {
      case MoodQuadrant.highEnergyPleasant:
        return AppColors.highEnergyPleasant;
      case MoodQuadrant.highEnergyUnpleasant:
        return AppColors.highEnergyUnpleasant;
      case MoodQuadrant.lowEnergyUnpleasant:
        return AppColors.lowEnergyUnpleasant;
      case MoodQuadrant.lowEnergyPleasant:
        return AppColors.lowEnergyPleasant;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(circumplexStateProvider);
    final words = circumplexEmotions
        .where((e) => e.quadrant == quadrant)
        .toList();
    final color = _quadrantColor(quadrant);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: words.map((word) {
        final isSelected = position.selectedWord == word.label;
        return ChoiceChip(
          label: Text(word.label),
          selected: isSelected,
          onSelected: (_) => onEmotionSelected(word),
          selectedColor: color.withOpacity(0.3),
          labelStyle: TextStyle(
            color: isSelected ? color : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? color : AppColors.textHint.withOpacity(0.3),
          ),
        );
      }).toList(),
    );
  }
}
