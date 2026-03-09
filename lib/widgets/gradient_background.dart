import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Static gradient background — lightweight, no animation controller.
/// Automatically adapts to light/dark mode.
class GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final List<Color>? secondaryColors;
  final List<Color>? darkColors;
  final List<Color>? darkSecondaryColors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const GradientBackground({
    super.key,
    required this.child,
    this.colors,
    this.secondaryColors,
    this.darkColors,
    this.darkSecondaryColors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradientColors = isDark
        ? (darkColors ?? [AppColors.darkBg, AppColors.darkBgSecondary])
        : (colors ?? [AppColors.cream, AppColors.lightBlush]);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin as Alignment,
          end: end as Alignment,
          colors: gradientColors,
        ),
      ),
      child: child,
    );
  }
}
