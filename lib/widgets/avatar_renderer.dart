import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/avatar_config.dart';
import 'avatar_parts.dart';

/// Widget that renders a custom avatar using CustomPainter.
/// Draws the avatar in layers: body → face → eyes → mouth → hair → accessories.
class AvatarRenderer extends StatelessWidget {
  final AvatarConfig config;
  final double size;

  const AvatarRenderer({
    super.key,
    required this.config,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AvatarPainter(config: config),
        size: Size(size, size),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  final AvatarConfig config;

  _AvatarPainter({required this.config});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width; // Assume square
    final cx = s / 2;
    final cy = s / 2;

    // Colors
    final skinColor = AvatarParts.skinTones[config.skinTone.clamp(0, 7)];
    final hairColor = AvatarParts.hairColors[config.hairColor.clamp(0, 9)];
    final clothingColor = AvatarParts.clothingColors[config.clothingColor.clamp(0, 7)];

    // 1. Draw body/clothing
    _drawClothing(canvas, s, cx, cy, clothingColor);

    // 2. Draw neck
    _drawNeck(canvas, s, cx, cy, skinColor);

    // 3. Draw face
    _drawFace(canvas, s, cx, cy, skinColor);

    // 4. Draw eyes
    _drawEyes(canvas, s, cx, cy);

    // 5. Draw mouth
    _drawMouth(canvas, s, cx, cy);

    // 6. Draw hair
    _drawHair(canvas, s, cx, cy, hairColor);

    // 7. Draw accessories
    _drawAccessory(canvas, s, cx, cy);
  }

  void _drawClothing(Canvas canvas, double s, double cx, double cy, Color color) {
    final clothingType = config.clothing.clamp(0, 8);
    final paint = Paint()..color = color;
    final darkPaint = Paint()..color = Color.lerp(color, const Color(0xFF000000), 0.2)!;

    // Body base (shoulders and torso)
    final bodyTop = cy + s * 0.28;
    final bodyPath = Path();

    switch (clothingType) {
      case 0: // T-Shirt
        bodyPath.moveTo(cx - s * 0.35, s);
        bodyPath.quadraticBezierTo(cx - s * 0.35, bodyTop + s * 0.05, cx - s * 0.25, bodyTop);
        bodyPath.lineTo(cx - s * 0.08, bodyTop - s * 0.02);
        bodyPath.quadraticBezierTo(cx, bodyTop - s * 0.04, cx + s * 0.08, bodyTop - s * 0.02);
        bodyPath.lineTo(cx + s * 0.25, bodyTop);
        bodyPath.quadraticBezierTo(cx + s * 0.35, bodyTop + s * 0.05, cx + s * 0.35, s);
        bodyPath.close();
        break;
      case 1: // V-Neck
        bodyPath.moveTo(cx - s * 0.35, s);
        bodyPath.quadraticBezierTo(cx - s * 0.35, bodyTop + s * 0.05, cx - s * 0.25, bodyTop);
        bodyPath.lineTo(cx, bodyTop + s * 0.08);
        bodyPath.lineTo(cx + s * 0.25, bodyTop);
        bodyPath.quadraticBezierTo(cx + s * 0.35, bodyTop + s * 0.05, cx + s * 0.35, s);
        bodyPath.close();
        break;
      case 3: // Hoodie
        bodyPath.moveTo(cx - s * 0.38, s);
        bodyPath.quadraticBezierTo(cx - s * 0.38, bodyTop + s * 0.02, cx - s * 0.28, bodyTop - s * 0.02);
        bodyPath.lineTo(cx - s * 0.1, bodyTop - s * 0.04);
        bodyPath.quadraticBezierTo(cx, bodyTop - s * 0.06, cx + s * 0.1, bodyTop - s * 0.04);
        bodyPath.lineTo(cx + s * 0.28, bodyTop - s * 0.02);
        bodyPath.quadraticBezierTo(cx + s * 0.38, bodyTop + s * 0.02, cx + s * 0.38, s);
        bodyPath.close();
        break;
      case 4: // Collared
        bodyPath.moveTo(cx - s * 0.35, s);
        bodyPath.quadraticBezierTo(cx - s * 0.35, bodyTop + s * 0.05, cx - s * 0.25, bodyTop);
        bodyPath.lineTo(cx - s * 0.12, bodyTop - s * 0.01);
        bodyPath.lineTo(cx - s * 0.06, bodyTop + s * 0.04);
        bodyPath.lineTo(cx, bodyTop - s * 0.01);
        bodyPath.lineTo(cx + s * 0.06, bodyTop + s * 0.04);
        bodyPath.lineTo(cx + s * 0.12, bodyTop - s * 0.01);
        bodyPath.lineTo(cx + s * 0.25, bodyTop);
        bodyPath.quadraticBezierTo(cx + s * 0.35, bodyTop + s * 0.05, cx + s * 0.35, s);
        bodyPath.close();
        break;
      case 8: // Turtleneck
        bodyPath.moveTo(cx - s * 0.35, s);
        bodyPath.quadraticBezierTo(cx - s * 0.35, bodyTop + s * 0.05, cx - s * 0.25, bodyTop - s * 0.02);
        bodyPath.lineTo(cx - s * 0.1, bodyTop - s * 0.06);
        bodyPath.quadraticBezierTo(cx, bodyTop - s * 0.08, cx + s * 0.1, bodyTop - s * 0.06);
        bodyPath.lineTo(cx + s * 0.25, bodyTop - s * 0.02);
        bodyPath.quadraticBezierTo(cx + s * 0.35, bodyTop + s * 0.05, cx + s * 0.35, s);
        bodyPath.close();
        break;
      default: // Generic shirt (Crew, Tank, Sweater, Jacket)
        bodyPath.moveTo(cx - s * 0.35, s);
        bodyPath.quadraticBezierTo(cx - s * 0.35, bodyTop + s * 0.05, cx - s * 0.25, bodyTop);
        bodyPath.quadraticBezierTo(cx, bodyTop - s * 0.04, cx + s * 0.25, bodyTop);
        bodyPath.quadraticBezierTo(cx + s * 0.35, bodyTop + s * 0.05, cx + s * 0.35, s);
        bodyPath.close();
    }

    canvas.drawPath(bodyPath, paint);

    // Collar detail line for some clothing types
    if (clothingType == 0 || clothingType == 2 || clothingType == 6) {
      final collarPaint = Paint()
        ..color = darkPaint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.008;
      final collarPath = Path();
      collarPath.moveTo(cx - s * 0.12, bodyTop);
      collarPath.quadraticBezierTo(cx, bodyTop - s * 0.02, cx + s * 0.12, bodyTop);
      canvas.drawPath(collarPath, collarPaint);
    }
  }

  void _drawNeck(Canvas canvas, double s, double cx, double cy, Color skinColor) {
    final neckPaint = Paint()..color = skinColor;
    final neckRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy + s * 0.22),
        width: s * 0.14,
        height: s * 0.12,
      ),
      Radius.circular(s * 0.03),
    );
    canvas.drawRRect(neckRect, neckPaint);
  }

  void _drawFace(Canvas canvas, double s, double cx, double cy, Color skinColor) {
    final facePaint = Paint()..color = skinColor;
    final faceShape = config.faceShape.clamp(0, 5);

    // Face center is slightly above center
    final faceCy = cy - s * 0.02;
    final faceW = s * 0.32;
    final faceH = s * 0.36;

    switch (faceShape) {
      case 0: // Oval
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, faceCy), width: faceW, height: faceH),
          facePaint,
        );
        break;
      case 1: // Round
        canvas.drawCircle(Offset(cx, faceCy), s * 0.17, facePaint);
        break;
      case 2: // Heart
        final heartPath = Path();
        heartPath.moveTo(cx, faceCy + faceH * 0.48);
        heartPath.cubicTo(cx - faceW * 0.7, faceCy + faceH * 0.1, cx - faceW * 0.6, faceCy - faceH * 0.4, cx, faceCy - faceH * 0.15);
        heartPath.cubicTo(cx + faceW * 0.6, faceCy - faceH * 0.4, cx + faceW * 0.7, faceCy + faceH * 0.1, cx, faceCy + faceH * 0.48);
        canvas.drawPath(heartPath, facePaint);
        break;
      case 3: // Square
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, faceCy), width: faceW, height: faceH * 0.95),
            Radius.circular(s * 0.04),
          ),
          facePaint,
        );
        break;
      case 4: // Long
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, faceCy), width: faceW * 0.88, height: faceH * 1.08),
          facePaint,
        );
        break;
      case 5: // Diamond
        final diamondPath = Path();
        diamondPath.moveTo(cx, faceCy - faceH * 0.48);
        diamondPath.lineTo(cx + faceW * 0.5, faceCy);
        diamondPath.lineTo(cx, faceCy + faceH * 0.48);
        diamondPath.lineTo(cx - faceW * 0.5, faceCy);
        diamondPath.close();
        // Smooth the diamond with a rounded rect overlay
        canvas.drawPath(diamondPath, facePaint);
        break;
    }

    // Subtle ear indicators
    final earPaint = Paint()..color = Color.lerp(skinColor, const Color(0xFF000000), 0.05)!;
    canvas.drawCircle(Offset(cx - faceW * 0.52, faceCy), s * 0.025, earPaint);
    canvas.drawCircle(Offset(cx + faceW * 0.52, faceCy), s * 0.025, earPaint);
  }

  void _drawEyes(Canvas canvas, double s, double cx, double cy) {
    final eyeStyle = config.eyeStyle.clamp(0, 8);
    final eyeY = cy - s * 0.06;
    final eyeSpacing = s * 0.08;
    final eyeColor = const Color(0xFF2C1B18);
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);
    final eyePaint = Paint()..color = eyeColor;
    final linePaint = Paint()
      ..color = eyeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.012
      ..strokeCap = StrokeCap.round;

    for (final xDir in [-1.0, 1.0]) {
      final ex = cx + xDir * eyeSpacing;

      switch (eyeStyle) {
        case 0: // Normal
          canvas.drawOval(
            Rect.fromCenter(center: Offset(ex, eyeY), width: s * 0.06, height: s * 0.04),
            whitePaint,
          );
          canvas.drawCircle(Offset(ex, eyeY), s * 0.016, eyePaint);
          break;
        case 1: // Happy (curved lines)
          final happyPath = Path();
          happyPath.moveTo(ex - s * 0.025, eyeY);
          happyPath.quadraticBezierTo(ex, eyeY - s * 0.025, ex + s * 0.025, eyeY);
          canvas.drawPath(happyPath, linePaint);
          break;
        case 2: // Surprised
          canvas.drawCircle(Offset(ex, eyeY), s * 0.025, whitePaint);
          canvas.drawCircle(
            Offset(ex, eyeY),
            s * 0.025,
            Paint()
              ..color = eyeColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * 0.008,
          );
          canvas.drawCircle(Offset(ex, eyeY), s * 0.012, eyePaint);
          break;
        case 3: // Sleepy
          final sleepyPath = Path();
          sleepyPath.moveTo(ex - s * 0.025, eyeY + s * 0.005);
          sleepyPath.quadraticBezierTo(ex, eyeY - s * 0.008, ex + s * 0.025, eyeY + s * 0.005);
          canvas.drawPath(sleepyPath, linePaint);
          break;
        case 4: // Wink (left normal, right wink)
          if (xDir < 0) {
            canvas.drawOval(
              Rect.fromCenter(center: Offset(ex, eyeY), width: s * 0.06, height: s * 0.04),
              whitePaint,
            );
            canvas.drawCircle(Offset(ex, eyeY), s * 0.016, eyePaint);
          } else {
            canvas.drawLine(Offset(ex - s * 0.022, eyeY), Offset(ex + s * 0.022, eyeY), linePaint);
          }
          break;
        case 5: // Cat eyes
          final catPath = Path();
          catPath.moveTo(ex - s * 0.03, eyeY);
          catPath.quadraticBezierTo(ex, eyeY - s * 0.02, ex + s * 0.03, eyeY - s * 0.01);
          catPath.quadraticBezierTo(ex, eyeY + s * 0.015, ex - s * 0.03, eyeY);
          canvas.drawPath(catPath, eyePaint);
          break;
        case 6: // Round
          canvas.drawCircle(Offset(ex, eyeY), s * 0.022, whitePaint);
          canvas.drawCircle(Offset(ex, eyeY), s * 0.014, eyePaint);
          break;
        case 7: // Narrow
          canvas.drawOval(
            Rect.fromCenter(center: Offset(ex, eyeY), width: s * 0.055, height: s * 0.02),
            whitePaint,
          );
          canvas.drawCircle(Offset(ex, eyeY), s * 0.008, eyePaint);
          break;
        case 8: // Lashes
          canvas.drawOval(
            Rect.fromCenter(center: Offset(ex, eyeY), width: s * 0.06, height: s * 0.04),
            whitePaint,
          );
          canvas.drawCircle(Offset(ex, eyeY), s * 0.016, eyePaint);
          // Lashes
          for (int i = -1; i <= 1; i++) {
            final lx = ex + i * s * 0.015;
            canvas.drawLine(
              Offset(lx, eyeY - s * 0.02),
              Offset(lx + i * s * 0.005, eyeY - s * 0.035),
              linePaint..strokeWidth = s * 0.006,
            );
          }
          linePaint.strokeWidth = s * 0.012;
          break;
      }
    }

    // Eyebrows
    final browPaint = Paint()
      ..color = AvatarParts.hairColors[config.hairColor.clamp(0, 9)]
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.012
      ..strokeCap = StrokeCap.round;

    for (final xDir in [-1.0, 1.0]) {
      final bx = cx + xDir * eyeSpacing;
      final browPath = Path();
      browPath.moveTo(bx - s * 0.025 * xDir.sign, eyeY - s * 0.04);
      browPath.quadraticBezierTo(bx, eyeY - s * 0.055, bx + s * 0.025 * xDir.sign, eyeY - s * 0.04);
      canvas.drawPath(browPath, browPaint);
    }
  }

  void _drawMouth(Canvas canvas, double s, double cx, double cy) {
    final mouthStyle = config.mouthStyle.clamp(0, 6);
    final mouthY = cy + s * 0.08;
    final mouthColor = const Color(0xFFCC6666);
    final linePaint = Paint()
      ..color = const Color(0xFF4A3322)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.01
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()..color = mouthColor;
    final darkFill = Paint()..color = const Color(0xFF3D1F1F);

    switch (mouthStyle) {
      case 0: // Smile
        final smilePath = Path();
        smilePath.moveTo(cx - s * 0.05, mouthY);
        smilePath.quadraticBezierTo(cx, mouthY + s * 0.035, cx + s * 0.05, mouthY);
        canvas.drawPath(smilePath, linePaint);
        break;
      case 1: // Grin
        final grinPath = Path();
        grinPath.moveTo(cx - s * 0.06, mouthY);
        grinPath.quadraticBezierTo(cx, mouthY + s * 0.045, cx + s * 0.06, mouthY);
        grinPath.quadraticBezierTo(cx, mouthY + s * 0.02, cx - s * 0.06, mouthY);
        canvas.drawPath(grinPath, fillPaint);
        // Teeth line
        canvas.drawLine(
          Offset(cx - s * 0.04, mouthY + s * 0.015),
          Offset(cx + s * 0.04, mouthY + s * 0.015),
          Paint()
            ..color = const Color(0xFFFFFFFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.008,
        );
        break;
      case 2: // Neutral
        canvas.drawLine(
          Offset(cx - s * 0.04, mouthY),
          Offset(cx + s * 0.04, mouthY),
          linePaint,
        );
        break;
      case 3: // Slight smile
        final slightPath = Path();
        slightPath.moveTo(cx - s * 0.035, mouthY);
        slightPath.quadraticBezierTo(cx, mouthY + s * 0.018, cx + s * 0.035, mouthY);
        canvas.drawPath(slightPath, linePaint);
        break;
      case 4: // Open
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, mouthY + s * 0.01), width: s * 0.06, height: s * 0.04),
          darkFill,
        );
        break;
      case 5: // Pout
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, mouthY), width: s * 0.04, height: s * 0.03),
          fillPaint,
        );
        break;
      case 6: // Tongue
        final tonguePath = Path();
        tonguePath.moveTo(cx - s * 0.05, mouthY);
        tonguePath.quadraticBezierTo(cx, mouthY + s * 0.035, cx + s * 0.05, mouthY);
        canvas.drawPath(tonguePath, linePaint);
        // Tongue
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, mouthY + s * 0.03), width: s * 0.03, height: s * 0.02),
          Paint()..color = const Color(0xFFFF6B6B),
        );
        break;
    }
  }

  void _drawHair(Canvas canvas, double s, double cx, double cy, Color hairColor) {
    final hairStyle = config.hairStyle.clamp(0, 15);
    final hairPaint = Paint()..color = hairColor;
    final faceCy = cy - s * 0.02;
    double baseHeadTop = faceCy - s * 0.19;
    if (config.faceShape == 4) baseHeadTop = faceCy - s * 0.20; // Long face
    final headTop = baseHeadTop;

    if (hairStyle == 15) return; // Bald

    switch (hairStyle) {
      case 0: // Short Crop
        final path = Path();
        path.addArc(
          Rect.fromCenter(center: Offset(cx, faceCy - s * 0.04), width: s * 0.36, height: s * 0.34),
          math.pi, math.pi,
        );
        path.close();
        canvas.drawPath(path, hairPaint);
        break;
      case 1: // Buzz Cut
        final path = Path();
        path.addArc(
          Rect.fromCenter(center: Offset(cx, faceCy - s * 0.02), width: s * 0.34, height: s * 0.32),
          math.pi * 0.9, math.pi * 1.2,
        );
        canvas.drawPath(path, hairPaint);
        break;
      case 2: // Side Part
        final path = Path();
        path.moveTo(cx - s * 0.18, faceCy);
        path.quadraticBezierTo(cx - s * 0.18, headTop, cx, headTop);
        path.quadraticBezierTo(cx + s * 0.2, headTop, cx + s * 0.18, faceCy - s * 0.08);
        path.lineTo(cx + s * 0.15, faceCy - s * 0.04);
        path.quadraticBezierTo(cx + s * 0.08, headTop + s * 0.04, cx - s * 0.02, headTop + s * 0.03);
        path.quadraticBezierTo(cx - s * 0.14, headTop + s * 0.02, cx - s * 0.15, faceCy);
        path.close();
        canvas.drawPath(path, hairPaint);
        break;
      case 3: // Slick Back
        final path = Path();
        path.addArc(
          Rect.fromCenter(center: Offset(cx, faceCy - s * 0.04), width: s * 0.38, height: s * 0.36),
          math.pi * 0.85, math.pi * 1.3,
        );
        canvas.drawPath(path, hairPaint);
        break;
      case 4: // Messy
        final path = Path();
        path.moveTo(cx - s * 0.2, faceCy - s * 0.04);
        for (int i = 0; i < 8; i++) {
          final angle = math.pi + (math.pi * i / 7);
          final r = s * 0.2 + (i.isEven ? s * 0.03 : 0);
          path.lineTo(cx + r * math.cos(angle), faceCy - s * 0.04 + r * math.sin(angle));
        }
        path.close();
        canvas.drawPath(path, hairPaint);
        break;
      case 5: // Long Straight
        final path = Path();
        path.moveTo(cx - s * 0.2, faceCy + s * 0.15);
        path.lineTo(cx - s * 0.18, faceCy);
        path.quadraticBezierTo(cx - s * 0.18, headTop, cx, headTop);
        path.quadraticBezierTo(cx + s * 0.18, headTop, cx + s * 0.18, faceCy);
        path.lineTo(cx + s * 0.2, faceCy + s * 0.15);
        path.lineTo(cx + s * 0.15, faceCy + s * 0.12);
        path.quadraticBezierTo(cx, headTop + s * 0.08, cx - s * 0.15, faceCy + s * 0.12);
        path.close();
        canvas.drawPath(path, hairPaint);
        break;
      case 6: // Long Wavy
        final path = Path();
        path.moveTo(cx - s * 0.22, faceCy + s * 0.18);
        path.quadraticBezierTo(cx - s * 0.2, faceCy + s * 0.1, cx - s * 0.18, faceCy);
        path.quadraticBezierTo(cx - s * 0.18, headTop, cx, headTop);
        path.quadraticBezierTo(cx + s * 0.18, headTop, cx + s * 0.18, faceCy);
        path.quadraticBezierTo(cx + s * 0.2, faceCy + s * 0.1, cx + s * 0.22, faceCy + s * 0.18);
        path.quadraticBezierTo(cx + s * 0.18, faceCy + s * 0.14, cx + s * 0.15, faceCy + s * 0.12);
        path.quadraticBezierTo(cx, headTop + s * 0.08, cx - s * 0.15, faceCy + s * 0.12);
        path.quadraticBezierTo(cx - s * 0.18, faceCy + s * 0.14, cx - s * 0.22, faceCy + s * 0.18);
        path.close();
        canvas.drawPath(path, hairPaint);
        break;
      case 7: // Bob
        final path = Path();
        path.moveTo(cx - s * 0.19, faceCy + s * 0.06);
        path.lineTo(cx - s * 0.18, faceCy);
        path.quadraticBezierTo(cx - s * 0.18, headTop, cx, headTop);
        path.quadraticBezierTo(cx + s * 0.18, headTop, cx + s * 0.18, faceCy);
        path.lineTo(cx + s * 0.19, faceCy + s * 0.06);
        path.quadraticBezierTo(cx, faceCy + s * 0.02, cx - s * 0.19, faceCy + s * 0.06);
        path.close();
        canvas.drawPath(path, hairPaint);
        break;
      case 8: // Pixie
        final path = Path();
        path.moveTo(cx - s * 0.17, faceCy - s * 0.02);
        path.quadraticBezierTo(cx - s * 0.18, headTop + s * 0.02, cx - s * 0.05, headTop);
        path.quadraticBezierTo(cx + s * 0.1, headTop - s * 0.02, cx + s * 0.18, faceCy - s * 0.06);
        path.lineTo(cx + s * 0.14, faceCy - s * 0.02);
        path.quadraticBezierTo(cx, headTop + s * 0.06, cx - s * 0.14, faceCy - s * 0.02);
        path.close();
        canvas.drawPath(path, hairPaint);
        break;
      case 9: // Afro
        canvas.drawCircle(Offset(cx, faceCy - s * 0.06), s * 0.24, hairPaint);
        break;
      case 10: // Curly
        final center = Offset(cx, faceCy - s * 0.06);
        for (int i = 0; i < 12; i++) {
          final angle = (2 * math.pi / 12) * i;
          final r = s * 0.2;
          final cx2 = center.dx + r * math.cos(angle);
          final cy2 = center.dy + r * math.sin(angle);
          if (angle > math.pi * 0.3 && angle < math.pi * 0.7) continue;
          canvas.drawCircle(Offset(cx2, cy2), s * 0.045, hairPaint);
        }
        // Fill top
        canvas.drawCircle(center, s * 0.16, hairPaint);
        break;
      case 11: // Mohawk
        final path = Path();
        path.moveTo(cx - s * 0.04, faceCy - s * 0.04);
        path.quadraticBezierTo(cx - s * 0.05, headTop - s * 0.08, cx, headTop - s * 0.12);
        path.quadraticBezierTo(cx + s * 0.05, headTop - s * 0.08, cx + s * 0.04, faceCy - s * 0.04);
        path.close();
        canvas.drawPath(path, hairPaint);
        break;
      case 12: // Braids
        final path = Path();
        path.moveTo(cx - s * 0.18, faceCy);
        path.quadraticBezierTo(cx - s * 0.18, headTop, cx, headTop);
        path.quadraticBezierTo(cx + s * 0.18, headTop, cx + s * 0.18, faceCy);
        path.quadraticBezierTo(cx, headTop + s * 0.08, cx - s * 0.18, faceCy);
        path.close();
        canvas.drawPath(path, hairPaint);
        // Braid strands
        for (final xDir in [-1.0, 1.0]) {
          for (int i = 0; i < 3; i++) {
            final by = faceCy + s * 0.04 + i * s * 0.04;
            canvas.drawCircle(
              Offset(cx + xDir * s * 0.16, by),
              s * 0.015,
              hairPaint,
            );
          }
        }
        break;
      case 13: // Bun
        final path = Path();
        path.addArc(
          Rect.fromCenter(center: Offset(cx, faceCy - s * 0.04), width: s * 0.36, height: s * 0.34),
          math.pi, math.pi,
        );
        path.close();
        canvas.drawPath(path, hairPaint);
        // Bun on top
        canvas.drawCircle(Offset(cx, headTop - s * 0.04), s * 0.06, hairPaint);
        break;
      case 14: // Ponytail
        final path = Path();
        path.addArc(
          Rect.fromCenter(center: Offset(cx, faceCy - s * 0.04), width: s * 0.36, height: s * 0.34),
          math.pi, math.pi,
        );
        path.close();
        canvas.drawPath(path, hairPaint);
        // Ponytail
        final tailPath = Path();
        tailPath.moveTo(cx + s * 0.12, headTop + s * 0.02);
        tailPath.quadraticBezierTo(cx + s * 0.25, headTop + s * 0.08, cx + s * 0.2, faceCy + s * 0.1);
        tailPath.quadraticBezierTo(cx + s * 0.18, faceCy + s * 0.05, cx + s * 0.1, headTop + s * 0.04);
        tailPath.close();
        canvas.drawPath(tailPath, hairPaint);
        break;
    }
  }

  void _drawAccessory(Canvas canvas, double s, double cx, double cy) {
    final accessory = config.accessory.clamp(0, 5);
    if (accessory == 0) return; // None

    final eyeY = cy - s * 0.06;
    final faceCy = cy - s * 0.02;
    final headTop = faceCy - s * 0.19;

    switch (accessory) {
      case 1: // Glasses
        final glassesPaint = Paint()
          ..color = const Color(0xFF333333)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.01;
        for (final xDir in [-1.0, 1.0]) {
          canvas.drawCircle(
            Offset(cx + xDir * s * 0.08, eyeY),
            s * 0.04,
            glassesPaint,
          );
        }
        // Bridge
        canvas.drawLine(
          Offset(cx - s * 0.04, eyeY),
          Offset(cx + s * 0.04, eyeY),
          glassesPaint,
        );
        // Arms
        canvas.drawLine(
          Offset(cx - s * 0.12, eyeY),
          Offset(cx - s * 0.17, eyeY - s * 0.01),
          glassesPaint,
        );
        canvas.drawLine(
          Offset(cx + s * 0.12, eyeY),
          Offset(cx + s * 0.17, eyeY - s * 0.01),
          glassesPaint,
        );
        break;
      case 2: // Sunglasses
        final lensPaint = Paint()..color = const Color(0xCC333333);
        final framePaint = Paint()
          ..color = const Color(0xFF1A1A1A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.012;
        for (final xDir in [-1.0, 1.0]) {
          final lensRect = Rect.fromCenter(
            center: Offset(cx + xDir * s * 0.08, eyeY),
            width: s * 0.1,
            height: s * 0.06,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(lensRect, Radius.circular(s * 0.015)),
            lensPaint,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(lensRect, Radius.circular(s * 0.015)),
            framePaint,
          );
        }
        canvas.drawLine(
          Offset(cx - s * 0.03, eyeY),
          Offset(cx + s * 0.03, eyeY),
          framePaint,
        );
        break;
      case 3: // Earrings
        final earringPaint = Paint()..color = const Color(0xFFFFD700);
        for (final xDir in [-1.0, 1.0]) {
          canvas.drawCircle(
            Offset(cx + xDir * s * 0.17, faceCy + s * 0.02),
            s * 0.012,
            earringPaint,
          );
        }
        break;
      case 4: // Headband
        final headbandPaint = Paint()
          ..color = const Color(0xFFCC6666)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.02;
        final headbandPath = Path();
        headbandPath.addArc(
          Rect.fromCenter(center: Offset(cx, faceCy - s * 0.04), width: s * 0.36, height: s * 0.34),
          math.pi * 0.85, math.pi * 1.3,
        );
        canvas.drawPath(headbandPath, headbandPaint);
        break;
      case 5: // Hat
        final hatPaint = Paint()..color = const Color(0xFF4A4A4A);
        // Brim
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, headTop + s * 0.04),
            width: s * 0.44,
            height: s * 0.08,
          ),
          hatPaint,
        );
        // Crown
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - s * 0.14, headTop - s * 0.1, s * 0.28, s * 0.16),
            Radius.circular(s * 0.04),
          ),
          hatPaint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) {
    return oldDelegate.config.toJsonString() != config.toJsonString();
  }
}
