import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/avatar_config.dart';

/// Draws a simple layered character using CustomPainter.
class CustomAvatar extends StatelessWidget {
  final AvatarConfig config;
  final double size;
  final bool isWalking;

  const CustomAvatar({
    super.key,
    required this.config,
    this.size = 120,
    this.isWalking = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AvatarPainter(config: config, isWalking: isWalking),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  final AvatarConfig config;
  final bool isWalking;

  _AvatarPainter({required this.config, this.isWalking = false});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final cx = s / 2;

    // Scale factors
    final headR = s * 0.16;
    final headCy = s * 0.18;

    // Body width based on bodyType
    final bodyHalfW = s * (0.12 + config.bodyType * 0.03);
    final bodyTop = headCy + headR * 0.85;
    final bodyBottom = s * 0.55;

    final legOffset = isWalking ? s * 0.02 : 0.0;

    final skinPaint = Paint()..color = config.skinColor;
    final hairPaint = Paint()..color = config.hairColor;

    // 2.5D gradient paints
    final shirtPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(cx - bodyHalfW, bodyTop),
        Offset(cx + bodyHalfW, bodyBottom),
        [
          _lighten(config.shirtColor, 0.15),
          config.shirtColor,
          _darken(config.shirtColor, 0.15),
        ],
        [0.0, 0.5, 1.0],
      );
    final pantsPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(cx - bodyHalfW, bodyBottom),
        Offset(cx + bodyHalfW, s * 0.78),
        [
          _lighten(config.pantsColor, 0.1),
          config.pantsColor,
          _darken(config.pantsColor, 0.1),
        ],
        [0.0, 0.5, 1.0],
      );
    final shoePaint = Paint()..color = config.shoeColor;

    // ── Drop shadow beneath character ──
    final shadowPaint = Paint()..color = const Color(0x33000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, s * 0.88),
        width: bodyHalfW * 2.5,
        height: s * 0.04,
      ),
      shadowPaint,
    );

    // ── Hat (accessory, drawn behind head) ──
    if (config.accessories.contains('hat')) {
      final hatPaint = Paint()
        ..color = config.shirtColor.withValues(alpha: 0.85);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, headCy - headR * 0.6),
            width: headR * 2.6,
            height: headR * 0.35,
          ),
          Radius.circular(headR * 0.15),
        ),
        hatPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            cx - headR * 0.85,
            headCy - headR * 1.5,
            headR * 1.7,
            headR * 1.0,
          ),
          Radius.circular(headR * 0.3),
        ),
        hatPaint,
      );
    }

    // ── Headband accessory (behind head) ──
    if (config.accessories.contains('headband')) {
      final headbandPaint = Paint()
        ..color = config.shirtColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.02;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, headCy), radius: headR * 1.05),
        3.4,
        2.5,
        false,
        headbandPaint,
      );
    }

    // ── Head ──
    final headGradientPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx - headR * 0.3, headCy - headR * 0.3),
        headR * 1.5,
        [_lighten(config.skinColor, 0.1), config.skinColor],
        [0.0, 1.0],
      );
    canvas.drawCircle(Offset(cx, headCy), headR, headGradientPaint);

    // ── Hair ──
    _drawHair(canvas, cx, headCy, headR, hairPaint, s);

    // ── Neck ──
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, bodyTop - s * 0.01),
        width: s * 0.06,
        height: s * 0.04,
      ),
      skinPaint,
    );

    // ── Shirt / Body ──
    final shirtPath = Path();
    if (config.shirtStyle == 1) {
      // Hoodie
      shirtPath.moveTo(cx - bodyHalfW * 1.1, bodyTop + s * 0.02);
      shirtPath.quadraticBezierTo(
        cx - bodyHalfW * 1.2,
        bodyTop - s * 0.02,
        cx - bodyHalfW * 0.4,
        bodyTop - s * 0.01,
      );
      shirtPath.lineTo(cx + bodyHalfW * 0.4, bodyTop - s * 0.01);
      shirtPath.quadraticBezierTo(
        cx + bodyHalfW * 1.2,
        bodyTop - s * 0.02,
        cx + bodyHalfW * 1.1,
        bodyTop + s * 0.02,
      );
      shirtPath.lineTo(cx + bodyHalfW, bodyBottom);
      shirtPath.lineTo(cx - bodyHalfW, bodyBottom);
      shirtPath.close();
    } else if (config.shirtStyle == 2) {
      // Tank
      shirtPath.moveTo(cx - bodyHalfW * 0.3, bodyTop);
      shirtPath.lineTo(cx - bodyHalfW, bodyTop + s * 0.06);
      shirtPath.lineTo(cx - bodyHalfW, bodyBottom);
      shirtPath.lineTo(cx + bodyHalfW, bodyBottom);
      shirtPath.lineTo(cx + bodyHalfW, bodyTop + s * 0.06);
      shirtPath.lineTo(cx + bodyHalfW * 0.3, bodyTop);
      shirtPath.close();
    } else if (config.shirtStyle == 3) {
      // Formal — collared shirt with V-neck
      shirtPath.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            cx - bodyHalfW,
            bodyTop,
            bodyHalfW * 2,
            bodyBottom - bodyTop,
          ),
          Radius.circular(s * 0.02),
        ),
      );
      // Collar triangles
      final collarPaint = Paint()..color = _lighten(config.shirtColor, 0.2);
      final leftCollar = Path()
        ..moveTo(cx - bodyHalfW * 0.4, bodyTop)
        ..lineTo(cx - bodyHalfW * 0.1, bodyTop + s * 0.05)
        ..lineTo(cx - bodyHalfW * 0.7, bodyTop + s * 0.03)
        ..close();
      final rightCollar = Path()
        ..moveTo(cx + bodyHalfW * 0.4, bodyTop)
        ..lineTo(cx + bodyHalfW * 0.1, bodyTop + s * 0.05)
        ..lineTo(cx + bodyHalfW * 0.7, bodyTop + s * 0.03)
        ..close();
      canvas.drawPath(shirtPath, shirtPaint);
      canvas.drawPath(leftCollar, collarPaint);
      canvas.drawPath(rightCollar, collarPaint);
      // Skip default shirtPath draw below
    } else if (config.shirtStyle == 4) {
      // Jacket — wider with lapels
      shirtPath.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            cx - bodyHalfW * 1.1,
            bodyTop,
            bodyHalfW * 2.2,
            bodyBottom - bodyTop,
          ),
          Radius.circular(s * 0.02),
        ),
      );
      // Center line
      final linePaint = Paint()
        ..color = _darken(config.shirtColor, 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.008;
      canvas.drawPath(shirtPath, shirtPaint);
      canvas.drawLine(
        Offset(cx, bodyTop + s * 0.02),
        Offset(cx, bodyBottom),
        linePaint,
      );
    } else if (config.shirtStyle == 5) {
      // Crop top — shorter body
      final cropBottom = bodyTop + (bodyBottom - bodyTop) * 0.6;
      shirtPath.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            cx - bodyHalfW,
            bodyTop,
            bodyHalfW * 2,
            cropBottom - bodyTop,
          ),
          Radius.circular(s * 0.02),
        ),
      );
      // Exposed midriff
      canvas.drawRect(
        Rect.fromLTWH(
          cx - bodyHalfW * 0.8,
          cropBottom,
          bodyHalfW * 1.6,
          bodyBottom - cropBottom,
        ),
        skinPaint,
      );
    } else {
      // T-shirt (default)
      shirtPath.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            cx - bodyHalfW,
            bodyTop,
            bodyHalfW * 2,
            bodyBottom - bodyTop,
          ),
          Radius.circular(s * 0.02),
        ),
      );
    }
    // Draw shirt for styles that haven't drawn yet (3 and 4 draw inside their branch)
    if (config.shirtStyle != 3 && config.shirtStyle != 4) {
      canvas.drawPath(shirtPath, shirtPaint);
    }

    // ── Arms (skin) ──
    final armW = s * 0.045;
    final armLen = s * 0.18;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - bodyHalfW - armW, bodyTop + s * 0.02, armW, armLen),
        Radius.circular(armW / 2),
      ),
      skinPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + bodyHalfW, bodyTop + s * 0.02, armW, armLen),
        Radius.circular(armW / 2),
      ),
      skinPaint,
    );

    // ── Watch accessory (on left wrist) ──
    if (config.accessories.contains('watch')) {
      final watchPaint = Paint()..color = const Color(0xFF455A64);
      final watchY = bodyTop + s * 0.02 + armLen - s * 0.03;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx - bodyHalfW - armW / 2, watchY),
            width: armW * 1.4,
            height: s * 0.025,
          ),
          Radius.circular(s * 0.005),
        ),
        watchPaint,
      );
      final facePaint = Paint()..color = const Color(0xFF90CAF9);
      canvas.drawCircle(
        Offset(cx - bodyHalfW - armW / 2, watchY),
        s * 0.01,
        facePaint,
      );
    }

    // ── Backpack accessory ──
    if (config.accessories.contains('backpack')) {
      final bpPaint = Paint()..color = _darken(config.shirtColor, 0.3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            cx + bodyHalfW - s * 0.01,
            bodyTop + s * 0.01,
            s * 0.06,
            s * 0.1,
          ),
          Radius.circular(s * 0.015),
        ),
        bpPaint,
      );
    }

    // ── Pants ──
    final pantsTop = bodyBottom;
    final pantsBottom = s * 0.78;
    final legW = bodyHalfW * 0.75;
    final gap = s * 0.02;

    if (config.pantsStyle == 1) {
      final shortsBottom = pantsTop + (pantsBottom - pantsTop) * 0.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            cx - bodyHalfW,
            pantsTop,
            legW - gap / 2,
            shortsBottom - pantsTop,
          ),
          Radius.circular(s * 0.01),
        ),
        pantsPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            cx + gap / 2,
            pantsTop,
            legW - gap / 2,
            shortsBottom - pantsTop,
          ),
          Radius.circular(s * 0.01),
        ),
        pantsPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            cx - bodyHalfW + (legW - armW) / 2,
            shortsBottom,
            armW,
            pantsBottom - shortsBottom + legOffset,
          ),
          Radius.circular(armW / 2),
        ),
        skinPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            cx + gap / 2 + (legW - armW) / 2,
            shortsBottom,
            armW,
            pantsBottom - shortsBottom - legOffset,
          ),
          Radius.circular(armW / 2),
        ),
        skinPaint,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            cx - bodyHalfW,
            pantsTop,
            legW - gap / 2,
            pantsBottom - pantsTop + legOffset,
          ),
          Radius.circular(s * 0.01),
        ),
        pantsPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            cx + gap / 2,
            pantsTop,
            legW - gap / 2,
            pantsBottom - pantsTop - legOffset,
          ),
          Radius.circular(s * 0.01),
        ),
        pantsPaint,
      );
    }

    // ── Shoes ──
    final shoeH = s * 0.05;
    final shoeW = legW + s * 0.02;
    final leftShoeY = pantsBottom + legOffset;
    final rightShoeY = pantsBottom - legOffset;

    if (config.shoeStyle == 2) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            cx - bodyHalfW - s * 0.01,
            leftShoeY,
            shoeW,
            shoeH * 0.6,
          ),
          Radius.circular(s * 0.01),
        ),
        shoePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            cx + gap / 2 - s * 0.01,
            rightShoeY,
            shoeW,
            shoeH * 0.6,
          ),
          Radius.circular(s * 0.01),
        ),
        shoePaint,
      );
    } else {
      final r = config.shoeStyle == 1 ? s * 0.02 : s * 0.015;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - bodyHalfW - s * 0.01, leftShoeY, shoeW, shoeH),
          Radius.circular(r),
        ),
        shoePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + gap / 2 - s * 0.01, rightShoeY, shoeW, shoeH),
          Radius.circular(r),
        ),
        shoePaint,
      );
    }

    // ── Eyes ──
    _drawEyes(canvas, cx, headCy, headR, s);

    // ── Mouth / Smile ──
    _drawSmile(canvas, cx, headCy, headR, s);

    // ── Glasses accessories (drawn over eyes) ──
    if (config.accessories.contains('sunglasses')) {
      _drawSunglasses(canvas, cx, headCy, headR, s);
    }
    if (config.accessories.contains('glassesRound')) {
      _drawGlassesRound(canvas, cx, headCy, headR, s);
    }
    if (config.accessories.contains('glassesSquare')) {
      _drawGlassesSquare(canvas, cx, headCy, headR, s);
    }

    // ── Chain accessory ──
    if (config.accessories.contains('chain')) {
      final chainPaint = Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.012
        ..strokeCap = StrokeCap.round;
      final chainPath = Path()
        ..moveTo(cx - s * 0.04, bodyTop + s * 0.01)
        ..quadraticBezierTo(
          cx,
          bodyTop + s * 0.07,
          cx + s * 0.04,
          bodyTop + s * 0.01,
        );
      canvas.drawPath(chainPath, chainPaint);
    }

    // ── Earring accessory ──
    if (config.accessories.contains('earring')) {
      final earPaint = Paint()..color = const Color(0xFFFFD54F);
      canvas.drawCircle(
        Offset(cx - headR * 1.0, headCy + headR * 0.1),
        s * 0.015,
        earPaint,
      );
    }
  }

  void _drawEyes(Canvas canvas, double cx, double cy, double r, double s) {
    final eyePaint = Paint()..color = const Color(0xFF212121);
    final leftEyeX = cx - r * 0.35;
    final rightEyeX = cx + r * 0.35;
    final eyeY = cy - r * 0.05;

    switch (config.eyeStyle) {
      case 0: // Round — solid circles
        canvas.drawCircle(Offset(leftEyeX, eyeY), s * 0.02, eyePaint);
        canvas.drawCircle(Offset(rightEyeX, eyeY), s * 0.02, eyePaint);
        break;
      case 1: // Almond — oval shapes
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(leftEyeX, eyeY),
            width: s * 0.045,
            height: s * 0.025,
          ),
          eyePaint,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(rightEyeX, eyeY),
            width: s * 0.045,
            height: s * 0.025,
          ),
          eyePaint,
        );
        break;
      case 2: // Narrow — thin horizontal ovals
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(leftEyeX, eyeY),
            width: s * 0.04,
            height: s * 0.012,
          ),
          eyePaint,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(rightEyeX, eyeY),
            width: s * 0.04,
            height: s * 0.012,
          ),
          eyePaint,
        );
        break;
      case 3: // Wide — larger circles
        canvas.drawCircle(Offset(leftEyeX, eyeY), s * 0.028, eyePaint);
        canvas.drawCircle(Offset(rightEyeX, eyeY), s * 0.028, eyePaint);
        // White highlight
        final highlightPaint = Paint()..color = const Color(0xFFFFFFFF);
        canvas.drawCircle(
          Offset(leftEyeX - s * 0.008, eyeY - s * 0.008),
          s * 0.008,
          highlightPaint,
        );
        canvas.drawCircle(
          Offset(rightEyeX - s * 0.008, eyeY - s * 0.008),
          s * 0.008,
          highlightPaint,
        );
        break;
      case 4: // Sleepy — half-closed crescents
        final sleepyPaint = Paint()
          ..color = const Color(0xFF212121)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.015
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(leftEyeX, eyeY),
            width: s * 0.04,
            height: s * 0.025,
          ),
          0.3,
          2.5,
          false,
          sleepyPaint,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(rightEyeX, eyeY),
            width: s * 0.04,
            height: s * 0.025,
          ),
          0.3,
          2.5,
          false,
          sleepyPaint,
        );
        break;
      default:
        canvas.drawCircle(Offset(leftEyeX, eyeY), s * 0.02, eyePaint);
        canvas.drawCircle(Offset(rightEyeX, eyeY), s * 0.02, eyePaint);
    }
  }

  void _drawSmile(Canvas canvas, double cx, double cy, double r, double s) {
    final mouthPaint = Paint()
      ..color = const Color(0xFFE57373)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.012
      ..strokeCap = StrokeCap.round;

    switch (config.smileStyle) {
      case 0: // Happy — curved arc upward
        final smilePath = Path()
          ..moveTo(cx - r * 0.25, cy + r * 0.3)
          ..quadraticBezierTo(cx, cy + r * 0.55, cx + r * 0.25, cy + r * 0.3);
        canvas.drawPath(smilePath, mouthPaint);
        break;
      case 1: // Neutral — straight line
        canvas.drawLine(
          Offset(cx - r * 0.18, cy + r * 0.35),
          Offset(cx + r * 0.18, cy + r * 0.35),
          mouthPaint,
        );
        break;
      case 2: // Smirk — one-sided curve
        final smirkPath = Path()
          ..moveTo(cx - r * 0.15, cy + r * 0.35)
          ..quadraticBezierTo(
            cx + r * 0.1,
            cy + r * 0.35,
            cx + r * 0.25,
            cy + r * 0.25,
          );
        canvas.drawPath(smirkPath, mouthPaint);
        break;
      case 3: // Gentle — slight upward curve
        final gentlePath = Path()
          ..moveTo(cx - r * 0.2, cy + r * 0.33)
          ..quadraticBezierTo(cx, cy + r * 0.42, cx + r * 0.2, cy + r * 0.33);
        canvas.drawPath(gentlePath, mouthPaint);
        break;
      default:
        final smilePath = Path()
          ..moveTo(cx - r * 0.2, cy + r * 0.3)
          ..quadraticBezierTo(cx, cy + r * 0.5, cx + r * 0.2, cy + r * 0.3);
        canvas.drawPath(smilePath, mouthPaint);
    }
  }

  void _drawSunglasses(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    double s,
  ) {
    final glassPaint = Paint()..color = const Color(0xCC212121);
    final glassR = r * 0.28;
    final glassY = cy - r * 0.05;
    canvas.drawCircle(Offset(cx - r * 0.35, glassY), glassR, glassPaint);
    canvas.drawCircle(Offset(cx + r * 0.35, glassY), glassR, glassPaint);
    final bridgePaint = Paint()
      ..color = const Color(0xFF212121)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.01;
    canvas.drawLine(
      Offset(cx - r * 0.35 + glassR, glassY),
      Offset(cx + r * 0.35 - glassR, glassY),
      bridgePaint,
    );
  }

  void _drawGlassesRound(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    double s,
  ) {
    final framePaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.008;
    final glassR = r * 0.28;
    final glassY = cy - r * 0.05;
    canvas.drawCircle(Offset(cx - r * 0.35, glassY), glassR, framePaint);
    canvas.drawCircle(Offset(cx + r * 0.35, glassY), glassR, framePaint);
    canvas.drawLine(
      Offset(cx - r * 0.35 + glassR, glassY),
      Offset(cx + r * 0.35 - glassR, glassY),
      framePaint,
    );
  }

  void _drawGlassesSquare(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    double s,
  ) {
    final framePaint = Paint()
      ..color = const Color(0xFF212121)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.008;
    final glassW = r * 0.5;
    final glassH = r * 0.4;
    final glassY = cy - r * 0.05;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - r * 0.35, glassY),
          width: glassW,
          height: glassH,
        ),
        Radius.circular(s * 0.005),
      ),
      framePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + r * 0.35, glassY),
          width: glassW,
          height: glassH,
        ),
        Radius.circular(s * 0.005),
      ),
      framePaint,
    );
    canvas.drawLine(
      Offset(cx - r * 0.35 + glassW / 2, glassY),
      Offset(cx + r * 0.35 - glassW / 2, glassY),
      framePaint,
    );
  }

  void _drawHair(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    Paint paint,
    double s,
  ) {
    // Hair highlight paint
    final highlightPaint = Paint()
      ..color = _lighten(config.hairColor, 0.25).withValues(alpha: 0.5);

    switch (config.hairStyle) {
      case 0: // Short
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.08),
          3.4,
          2.5,
          true,
          paint,
        );
        // Highlight streak
        canvas.drawArc(
          Rect.fromCircle(
            center: Offset(cx - r * 0.2, cy - r * 0.1),
            radius: r * 0.6,
          ),
          3.6,
          1.0,
          false,
          highlightPaint
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.015,
        );
        break;
      case 1: // Medium
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.12),
          3.0,
          3.3,
          true,
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - r * 1.15, cy - r * 0.2, r * 0.25, r * 1.0),
            Radius.circular(r * 0.1),
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx + r * 0.9, cy - r * 0.2, r * 0.25, r * 1.0),
            Radius.circular(r * 0.1),
          ),
          paint,
        );
        break;
      case 2: // Long
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.12),
          3.0,
          3.3,
          true,
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - r * 1.15, cy - r * 0.2, r * 0.3, r * 1.8),
            Radius.circular(r * 0.12),
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx + r * 0.85, cy - r * 0.2, r * 0.3, r * 1.8),
            Radius.circular(r * 0.12),
          ),
          paint,
        );
        break;
      case 3: // Buzz
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.03),
          3.6,
          2.0,
          true,
          paint,
        );
        break;
      case 4: // Curly
        for (var i = 0; i < 8; i++) {
          final angle = 3.14 + (i * 0.4) - 0.2;
          final dx = cx + r * 1.05 * _cos(angle);
          final dy = cy + r * 1.05 * _sin(angle);
          canvas.drawCircle(Offset(dx, dy), r * 0.25, paint);
        }
        break;
      case 5: // Ponytail
        // Base hair on top
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.1),
          3.2,
          2.8,
          true,
          paint,
        );
        // Ponytail tail going down-right
        final tailPath = Path()
          ..moveTo(cx + r * 0.6, cy - r * 0.5)
          ..quadraticBezierTo(
            cx + r * 1.8,
            cy - r * 0.3,
            cx + r * 1.4,
            cy + r * 1.0,
          );
        canvas.drawPath(
          tailPath,
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.35
            ..strokeCap = StrokeCap.round,
        );
        paint.style = PaintingStyle.fill; // Reset
        // Hair tie
        final tiePaint = Paint()..color = const Color(0xFFE57373);
        canvas.drawCircle(
          Offset(cx + r * 0.7, cy - r * 0.4),
          r * 0.12,
          tiePaint,
        );
        break;
      case 6: // Braids
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.1),
          3.0,
          3.3,
          true,
          paint,
        );
        // Two braids hanging down
        for (var side = -1; side <= 1; side += 2) {
          final braidX = cx + side * r * 0.9;
          for (var j = 0; j < 5; j++) {
            final by = cy + r * 0.2 + j * r * 0.35;
            final bx =
                braidX + (j % 2 == 0 ? side * r * 0.08 : -side * r * 0.08);
            canvas.drawCircle(Offset(bx, by), r * 0.13, paint);
          }
        }
        break;
      case 7: // Afro
        canvas.drawCircle(Offset(cx, cy - r * 0.2), r * 1.6, paint);
        // Highlight
        canvas.drawCircle(
          Offset(cx - r * 0.4, cy - r * 0.8),
          r * 0.4,
          highlightPaint..style = PaintingStyle.fill,
        );
        break;
      case 8: // Bald — no hair drawn
        break;
    }
  }

  double _cos(double a) => a == 0 ? 1 : (a * 0.017453292519943).cosOf();
  double _sin(double a) => a == 0 ? 0 : (a * 0.017453292519943).sinOf();

  static Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  static Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.isWalking != isWalking;
  }
}

// Extension to avoid importing dart:math everywhere in the painter
extension _TrigExt on double {
  double cosOf() {
    return _cosVal(this);
  }

  double sinOf() {
    return _sinVal(this);
  }
}

double _cosVal(double rad) {
  double x = rad % (2 * 3.141592653589793);
  double sum = 1.0;
  double term = 1.0;
  for (int i = 1; i <= 10; i++) {
    term *= -x * x / ((2 * i - 1) * (2 * i));
    sum += term;
  }
  return sum;
}

double _sinVal(double rad) {
  double x = rad % (2 * 3.141592653589793);
  double sum = x;
  double term = x;
  for (int i = 1; i <= 10; i++) {
    term *= -x * x / ((2 * i) * (2 * i + 1));
    sum += term;
  }
  return sum;
}
