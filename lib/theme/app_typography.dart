import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// MindHaven Typography System
/// Premium editorial style with generous line heights.
class AppTypography {
  AppTypography._();

  // ─── Hero Heading ───
  // Playfair Display SemiBold — for main headings
  static TextStyle heroHeading({Color? color}) => GoogleFonts.playfairDisplay(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: color ?? AppColors.textPrimary,
    height: 1.4,
    letterSpacing: -0.5,
  );

  // ─── Section Heading ───
  static TextStyle sectionHeading({Color? color}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
        height: 1.4,
      );

  // ─── Emotional / Quote Text ───
  // Playfair Display Italic — for quotes and emotional phrases
  static TextStyle emotionalText({Color? color}) => GoogleFonts.playfairDisplay(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: color ?? AppColors.textSecondary,
    height: 1.6,
  );

  // ─── Subtitle ───
  static TextStyle subtitle({Color? color}) => GoogleFonts.lora(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: color ?? AppColors.textSecondary,
    height: 1.5,
  );

  // ─── Journal Body ───
  // Lora Regular — for journal text and long-form content
  static TextStyle journalBody({Color? color}) => GoogleFonts.lora(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: color ?? AppColors.textPrimary,
    height: 1.6,
  );

  // ─── Body Text ───
  static TextStyle body({Color? color}) => GoogleFonts.lora(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: color ?? AppColors.textPrimary,
    height: 1.5,
  );

  // ─── UI Label ───
  // Inter Light — for buttons, navigation, and small text
  static TextStyle uiLabel({Color? color}) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w300,
    color: color ?? AppColors.textPrimary,
    height: 1.4,
  );

  // ─── Button Text ───
  static TextStyle buttonText({Color? color}) => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: color ?? AppColors.textPrimary,
    height: 1.4,
    letterSpacing: 0.3,
  );

  // ─── Caption / Small Text ───
  static TextStyle caption({Color? color}) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w300,
    color: color ?? AppColors.textTertiary,
    height: 1.4,
  );

  // ─── OTP Digit ───
  static TextStyle otpDigit({Color? color}) => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: color ?? AppColors.textPrimary,
    height: 1.2,
    letterSpacing: 2,
  );
}
