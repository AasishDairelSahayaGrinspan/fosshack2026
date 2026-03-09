import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Unravel Typography System
/// Cached base styles — GoogleFonts called once, then copyWith for colors.
class AppTypography {
  AppTypography._();

  // ─── Cached base styles (created once) ───
  static final TextStyle _playfairBase = GoogleFonts.playfairDisplay();
  static final TextStyle _loraBase = GoogleFonts.lora();
  static final TextStyle _interBase = GoogleFonts.inter();

  // ─── Hero Heading ───
  static TextStyle heroHeading({Color? color}) => _playfairBase.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: color ?? AppColors.textPrimary,
    height: 1.4,
    letterSpacing: -0.5,
  );

  // ─── Section Heading ───
  static TextStyle sectionHeading({Color? color}) => _playfairBase.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: color ?? AppColors.textPrimary,
    height: 1.4,
  );

  // ─── Emotional / Quote Text ───
  static TextStyle emotionalText({Color? color}) => _playfairBase.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: color ?? AppColors.textSecondary,
    height: 1.6,
  );

  // ─── Subtitle ───
  static TextStyle subtitle({Color? color}) => _loraBase.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: color ?? AppColors.textSecondary,
    height: 1.5,
  );

  // ─── Journal Body ───
  static TextStyle journalBody({Color? color}) => _loraBase.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: color ?? AppColors.textPrimary,
    height: 1.6,
  );

  // ─── Body Text ───
  static TextStyle body({Color? color}) => _loraBase.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: color ?? AppColors.textPrimary,
    height: 1.5,
  );

  // ─── UI Label ───
  static TextStyle uiLabel({Color? color}) => _interBase.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w300,
    color: color ?? AppColors.textPrimary,
    height: 1.4,
  );

  // ─── Button Text ───
  static TextStyle buttonText({Color? color}) => _interBase.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: color ?? AppColors.textPrimary,
    height: 1.4,
    letterSpacing: 0.3,
  );

  // ─── Caption ───
  static TextStyle caption({Color? color}) => _interBase.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w300,
    color: color ?? AppColors.textTertiary,
    height: 1.4,
  );

  // ─── OTP Digit ───
  static TextStyle otpDigit({Color? color}) => _interBase.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: color ?? AppColors.textPrimary,
    height: 1.2,
    letterSpacing: 2,
  );

  // ─── Context-aware versions ───
  static TextStyle heroHeadingC(BuildContext context) =>
      heroHeading(color: AppColors.primary(context));

  static TextStyle sectionHeadingC(BuildContext context) =>
      sectionHeading(color: AppColors.primary(context));

  static TextStyle emotionalTextC(BuildContext context) =>
      emotionalText(color: AppColors.secondary(context));

  static TextStyle subtitleC(BuildContext context) =>
      subtitle(color: AppColors.secondary(context));

  static TextStyle bodyC(BuildContext context) =>
      body(color: AppColors.primary(context));

  static TextStyle journalBodyC(BuildContext context) =>
      journalBody(color: AppColors.primary(context));

  static TextStyle uiLabelC(BuildContext context) =>
      uiLabel(color: AppColors.primary(context));

  static TextStyle buttonTextC(BuildContext context) =>
      buttonText(color: AppColors.primary(context));

  static TextStyle captionC(BuildContext context) =>
      caption(color: AppColors.tertiary(context));
}
