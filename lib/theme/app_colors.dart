import 'package:flutter/material.dart';

/// MindHaven Color System
/// Soft premium tones — no sharp neon, no pure black, no heavy shadows.
class AppColors {
  AppColors._();

  // ─── Primary Background Gradient Sets ───
  // Warm Lavender → Soft Peach
  static const Color warmLavender = Color(0xFFE8D5E0);
  static const Color softPeach = Color(0xFFF5E0D3);

  // Mist Blue → Pale Lilac
  static const Color mistBlue = Color(0xFFD6E4EF);
  static const Color paleLilac = Color(0xFFE8DCF0);

  // Cream → Light Blush
  static const Color cream = Color(0xFFF7F3EE);
  static const Color lightBlush = Color(0xFFF5E1E0);

  // ─── Gradient Presets ───
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

  // ─── Card & Surface ───
  static const Color cardBackground = Color(0xFFFAF8F6);
  static const Color frostedGlass = Color(0x99FFFFFF);
  static const Color frostedGlassBorder = Color(0x33FFFFFF);

  // ─── Accent Colors ───
  static const Color sageGreen = Color(0xFF9CB5A0);
  static const Color warmCoral = Color(0xFFE8A598);
  static const Color softIndigo = Color(0xFF9BA4CC);

  // ─── Text Colors (no pure black) ───
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textOnDark = Color(0xFFFAF8F6);

  // ─── Misc ───
  static const Color divider = Color(0xFFE8E4E0);
  static const Color inputBorder = Color(0xFFDDD8D3);
  static const Color inputFocusBorder = Color(0xFFBDB3C7);
  static const Color shadow = Color(0x0D000000); // 5% opacity black

  // ─── Soft Shadows ───
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
}
