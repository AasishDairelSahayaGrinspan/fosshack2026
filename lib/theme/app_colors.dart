import 'package:flutter/material.dart';

/// Unravel Color System
///
/// Light mode color policy:
/// - Allowed base colors: #304057, #DA5E5A, #E2814D, #FDB903
/// - Allowed extras: black/white neutrals and opacity variants
///
/// Dark mode policy:
/// - Pure black surfaces with the same accent colors as light mode.
class AppColors {
  AppColors._();

  // Canonical palette
  static const Color ink304057 = Color(0xFF304057);
  static const Color coralDa5e5a = Color(0xFFDA5E5A);
  static const Color orangeE2814d = Color(0xFFE2814D);
  static const Color amberFdb903 = Color(0xFFFDB903);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Legacy light gradient tokens mapped to palette tints
  static const Color warmLavender = Color(0x1ADA5E5A);
  static const Color softPeach = Color(0x1AE2814D);
  static const Color mistBlue = Color(0x14304057);
  static const Color paleLilac = Color(0x14DA5E5A);
  static const Color cream = white;
  static const Color lightBlush = Color(0x1AFDB903);

  // Dark mode surfaces (pure black)
  static const Color darkBg = black;
  static const Color darkBgSecondary = black;
  static const Color darkSurface = black;
  static const Color darkCard = black;
  static const Color darkCardBorder = Color(0x66304057);

  // Gradient presets
  static const splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warmLavender, softPeach],
  );

  static const loginGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [mistBlue, paleLilac],
  );

  static const homeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cream, lightBlush],
  );

  // Card & surface (light)
  static const Color cardBackground = white;
  static const Color frostedGlass = Color(0xF2FFFFFF);
  static const Color frostedGlassBorder = Color(0x22304057);

  // Accent colors (shared across themes)
  static const Color sageGreen = orangeE2814d;
  static const Color warmCoral = amberFdb903;
  static const Color softIndigo = coralDa5e5a;

  // Text colors (light)
  static const Color textPrimary = ink304057;
  static const Color textSecondary = Color(0xCC304057);
  static const Color textTertiary = Color(0x99304057);
  static const Color textOnDark = white;

  // Text colors (dark)
  static const Color darkTextPrimary = white;
  static const Color darkTextSecondary = Color(0xCCFFFFFF);
  static const Color darkTextTertiary = Color(0x99FFFFFF);

  // Misc (light)
  static const Color divider = Color(0x33304057);
  static const Color inputBorder = Color(0x55304057);
  static const Color inputFocusBorder = coralDa5e5a;
  static const Color shadow = Color(0x1A304057);

  // Misc (dark)
  static const Color darkDivider = Color(0x55FFFFFF);
  static const Color darkShadow = Color(0x66000000);

  // Soft shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: shadow,
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: shadow,
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get darkSoftShadow => [
    BoxShadow(
      color: darkShadow,
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  // Context-aware helpers
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBg : cream;

  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkCard
      : cardBackground;

  static Color cardBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkCardBorder
      : divider;

  static Color primary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkTextPrimary
      : textPrimary;

  static Color secondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkTextSecondary
      : textSecondary;

  static Color tertiary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkTextTertiary
      : textTertiary;

  static Color dividerColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkDivider : divider;

  static Color shadowColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkShadow : shadow;

  static List<BoxShadow> cardShadow(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkSoftShadow
      : subtleShadow;

  static Color frosted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0x33000000)
      : frostedGlass;

  static Color frostedBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0x33FFFFFF)
      : frostedGlassBorder;

  static List<Color> bgGradient(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? [darkBg, darkBgSecondary]
      : [cream, lightBlush];

  static List<Color> bgGradientAlt(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? [darkBgSecondary, darkSurface]
      : [paleLilac, softPeach];
}
