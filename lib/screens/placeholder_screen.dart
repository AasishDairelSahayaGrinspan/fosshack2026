import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/gradient_background.dart';

/// Placeholder screen for tabs not yet built.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    this.message = 'Coming soon',
  });

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      colors: const [AppColors.cream, AppColors.lightBlush],
      secondaryColors: const [AppColors.paleLilac, AppColors.cream],
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.softIndigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: AppColors.softIndigo, size: 32),
              ),
              const SizedBox(height: 20),
              Text(title, style: AppTypography.sectionHeading()),
              const SizedBox(height: 8),
              Text(message, style: AppTypography.subtitle()),
            ],
          ),
        ),
      ),
    );
  }
}
