import 'package:flutter/material.dart';

abstract final class AppColors {
  // Quadrant colours (Circumplex model)
  static const Color highEnergyPleasant = Color(0xFFFFD700); // Yellow – Q1
  static const Color highEnergyUnpleasant = Color(0xFFFF4444); // Red – Q2
  static const Color lowEnergyUnpleasant = Color(0xFF4444FF); // Blue – Q3
  static const Color lowEnergyPleasant = Color(0xFF44BB44); // Green – Q4

  // Brand
  static const Color primary = Color(0xFF6C3FC5);
  static const Color primaryLight = Color(0xFF9B72E8);
  static const Color primaryDark = Color(0xFF4A1FA0);

  // Surfaces
  static const Color background = Color(0xFFF8F6FD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0ECF7);

  // Text
  static const Color textPrimary = Color(0xFF1C1B1F);
  static const Color textSecondary = Color(0xFF49454F);
  static const Color textHint = Color(0xFF79747E);

  // Semantic
  static const Color error = Color(0xFFB3261E);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);

  /// Returns the colour associated with a given quadrant index (0-3).
  static Color quadrantColor(int index) {
    return switch (index) {
      0 => highEnergyPleasant,
      1 => highEnergyUnpleasant,
      2 => lowEnergyUnpleasant,
      3 => lowEnergyPleasant,
      _ => primary,
    };
  }
}
