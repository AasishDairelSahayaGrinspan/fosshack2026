import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/circumplex_data.dart';

class CircumplexWheel extends ConsumerWidget {
  final void Function(MoodQuadrant quadrant) onQuadrantSelected;
  const CircumplexWheel({super.key, required this.onQuadrantSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _QuadrantTile(
          color: AppColors.highEnergyPleasant,
          label: 'High Energy\nPleasant',
          quadrant: MoodQuadrant.highEnergyPleasant,
          onTap: () => onQuadrantSelected(MoodQuadrant.highEnergyPleasant),
        ),
        _QuadrantTile(
          color: AppColors.highEnergyUnpleasant,
          label: 'High Energy\nUnpleasant',
          quadrant: MoodQuadrant.highEnergyUnpleasant,
          onTap: () => onQuadrantSelected(MoodQuadrant.highEnergyUnpleasant),
        ),
        _QuadrantTile(
          color: AppColors.lowEnergyPleasant,
          label: 'Low Energy\nPleasant',
          quadrant: MoodQuadrant.lowEnergyPleasant,
          onTap: () => onQuadrantSelected(MoodQuadrant.lowEnergyPleasant),
        ),
        _QuadrantTile(
          color: AppColors.lowEnergyUnpleasant,
          label: 'Low Energy\nUnpleasant',
          quadrant: MoodQuadrant.lowEnergyUnpleasant,
          onTap: () => onQuadrantSelected(MoodQuadrant.lowEnergyUnpleasant),
        ),
      ],
    );
  }
}

class _QuadrantTile extends StatelessWidget {
  final Color color;
  final String label;
  final MoodQuadrant quadrant;
  final VoidCallback onTap;

  const _QuadrantTile({
    required this.color,
    required this.label,
    required this.quadrant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.3),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
