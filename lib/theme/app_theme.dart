import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Unravel Theme
/// Calm, breathable, premium with shared palette accents.
class AppTheme {
  AppTheme._();

  // Spacing constants
  static const double spacingXS = 8;
  static const double spacingSM = 12;
  static const double spacingMD = 16;
  static const double spacingLG = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 16,
  );

  // Border radius
  static const double radiusCard = 22;
  static const double radiusButton = 999;
  static const double radiusInput = 16;
  static const double radiusSmall = 12;

  // Animation durations
  static const Duration fadeInDuration = Duration(milliseconds: 350);
  static const Duration slideInDuration = Duration(milliseconds: 400);
  static const Duration tapScaleDuration = Duration(milliseconds: 150);

  // Animation curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve gentleCurve = Curves.easeOut;

  // Light mode source colors must come from AppColors palette policy.
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.cream,
    colorScheme: const ColorScheme.light(
      primary: AppColors.softIndigo,
      secondary: AppColors.sageGreen,
      error: AppColors.warmCoral,
      surface: AppColors.cardBackground,
      onPrimary: AppColors.textOnDark,
      onSecondary: AppColors.textOnDark,
      onSurface: AppColors.textPrimary,
      onError: AppColors.textOnDark,
    ),
    dividerColor: AppColors.divider,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
  );

  // Dark mode is pure black surfaces with the same accent palette.
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.softIndigo,
      secondary: AppColors.sageGreen,
      error: AppColors.warmCoral,
      surface: AppColors.darkCard,
      onPrimary: AppColors.darkTextPrimary,
      onSecondary: AppColors.darkTextPrimary,
      onSurface: AppColors.darkTextPrimary,
      onError: AppColors.darkTextPrimary,
    ),
    dividerColor: AppColors.darkDivider,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
  );
}
