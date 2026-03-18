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
    final shirtPaint = Paint()..color = config.shirtColor;
    final pantsPaint = Paint()..color = config.pantsColor;
    final shoePaint = Paint()..color = config.shoeColor;

    // ── Hat (accessory, drawn behind head) ──
    if (config.accessories.contains('hat')) {
      final hatPaint = Paint()..color = config.shirtColor.withValues(alpha: 0.85);
      // Brim
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, headCy - headR * 0.6), width: headR * 2.6, height: headR * 0.35),
          Radius.circular(headR * 0.15),
        ),
        hatPaint,
      );
      // Crown
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - headR * 0.85, headCy - headR * 1.5, headR * 1.7, headR * 1.0),
          Radius.circular(headR * 0.3),
        ),
        hatPaint,
      );
    }

    // ── Head ──
    canvas.drawCircle(Offset(cx, headCy), headR, skinPaint);

    // ── Hair ──
    _drawHair(canvas, cx, headCy, headR, hairPaint);

    // ── Neck ──
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, bodyTop - s * 0.01), width: s * 0.06, height: s * 0.04),
      skinPaint,
    );

    // ── Shirt / Body ──
    final shirtPath = Path();
    if (config.shirtStyle == 1) {
      // Hoodie — rounded top with wider shoulders
      shirtPath.moveTo(cx - bodyHalfW * 1.1, bodyTop + s * 0.02);
      shirtPath.quadraticBezierTo(cx - bodyHalfW * 1.2, bodyTop - s * 0.02, cx - bodyHalfW * 0.4, bodyTop - s * 0.01);
      shirtPath.lineTo(cx + bodyHalfW * 0.4, bodyTop - s * 0.01);
      shirtPath.quadraticBezierTo(cx + bodyHalfW * 1.2, bodyTop - s * 0.02, cx + bodyHalfW * 1.1, bodyTop + s * 0.02);
      shirtPath.lineTo(cx + bodyHalfW, bodyBottom);
      shirtPath.lineTo(cx - bodyHalfW, bodyBottom);
      shirtPath.close();
    } else if (config.shirtStyle == 2) {
      // Tank — narrow straps
      shirtPath.moveTo(cx - bodyHalfW * 0.3, bodyTop);
      shirtPath.lineTo(cx - bodyHalfW, bodyTop + s * 0.06);
      shirtPath.lineTo(cx - bodyHalfW, bodyBottom);
      shirtPath.lineTo(cx + bodyHalfW, bodyBottom);
      shirtPath.lineTo(cx + bodyHalfW, bodyTop + s * 0.06);
      shirtPath.lineTo(cx + bodyHalfW * 0.3, bodyTop);
      shirtPath.close();
    } else {
      // T-shirt
      shirtPath.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - bodyHalfW, bodyTop, bodyHalfW * 2, bodyBottom - bodyTop),
        Radius.circular(s * 0.02),
      ));
    }
    canvas.drawPath(shirtPath, shirtPaint);

    // ── Arms (skin) ──
    final armW = s * 0.045;
    final armLen = s * 0.18;
    // Left arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - bodyHalfW - armW, bodyTop + s * 0.02, armW, armLen),
        Radius.circular(armW / 2),
      ),
      skinPaint,
    );
    // Right arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + bodyHalfW, bodyTop + s * 0.02, armW, armLen),
        Radius.circular(armW / 2),
      ),
      skinPaint,
    );

    // ── Pants ──
    final pantsTop = bodyBottom;
    final pantsBottom = s * 0.78;
    final legW = bodyHalfW * 0.75;
    final gap = s * 0.02;

    if (config.pantsStyle == 1) {
      // Shorts — shorter
      final shortsBottom = pantsTop + (pantsBottom - pantsTop) * 0.5;
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - bodyHalfW, pantsTop, legW - gap / 2, shortsBottom - pantsTop),
        Radius.circular(s * 0.01),
      ), pantsPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + gap / 2, pantsTop, legW - gap / 2, shortsBottom - pantsTop),
        Radius.circular(s * 0.01),
      ), pantsPaint);
      // Exposed legs
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - bodyHalfW + (legW - armW) / 2, shortsBottom, armW, pantsBottom - shortsBottom + legOffset),
        Radius.circular(armW / 2),
      ), skinPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + gap / 2 + (legW - armW) / 2, shortsBottom, armW, pantsBottom - shortsBottom - legOffset),
        Radius.circular(armW / 2),
      ), skinPaint);
    } else {
      // Jeans / Joggers
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - bodyHalfW, pantsTop, legW - gap / 2, pantsBottom - pantsTop + legOffset),
        Radius.circular(s * 0.01),
      ), pantsPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + gap / 2, pantsTop, legW - gap / 2, pantsBottom - pantsTop - legOffset),
        Radius.circular(s * 0.01),
      ), pantsPaint);
    }

    // ── Shoes ──
    final shoeH = s * 0.05;
    final shoeW = legW + s * 0.02;
    final leftShoeY = pantsBottom + legOffset;
    final rightShoeY = pantsBottom - legOffset;

    if (config.shoeStyle == 2) {
      // Sandals — thinner
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - bodyHalfW - s * 0.01, leftShoeY, shoeW, shoeH * 0.6),
        Radius.circular(s * 0.01),
      ), shoePaint);
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + gap / 2 - s * 0.01, rightShoeY, shoeW, shoeH * 0.6),
        Radius.circular(s * 0.01),
      ), shoePaint);
    } else {
      // Sneakers / Boots
      final r = config.shoeStyle == 1 ? s * 0.02 : s * 0.015;
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - bodyHalfW - s * 0.01, leftShoeY, shoeW, shoeH),
        Radius.circular(r),
      ), shoePaint);
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + gap / 2 - s * 0.01, rightShoeY, shoeW, shoeH),
        Radius.circular(r),
      ), shoePaint);
    }

    // ── Eyes ──
    final eyePaint = Paint()..color = const Color(0xFF212121);
    canvas.drawCircle(Offset(cx - headR * 0.35, headCy - headR * 0.05), s * 0.02, eyePaint);
    canvas.drawCircle(Offset(cx + headR * 0.35, headCy - headR * 0.05), s * 0.02, eyePaint);

    // ── Mouth — small smile ──
    final mouthPaint = Paint()
      ..color = const Color(0xFFE57373)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.012
      ..strokeCap = StrokeCap.round;
    final smilePath = Path()
      ..moveTo(cx - headR * 0.2, headCy + headR * 0.3)
      ..quadraticBezierTo(cx, headCy + headR * 0.5, cx + headR * 0.2, headCy + headR * 0.3);
    canvas.drawPath(smilePath, mouthPaint);

    // ── Sunglasses accessory ──
    if (config.accessories.contains('sunglasses')) {
      final glassPaint = Paint()..color = const Color(0xCC212121);
      final glassR = headR * 0.28;
      final glassY = headCy - headR * 0.05;
      canvas.drawCircle(Offset(cx - headR * 0.35, glassY), glassR, glassPaint);
      canvas.drawCircle(Offset(cx + headR * 0.35, glassY), glassR, glassPaint);
      final bridgePaint = Paint()
        ..color = const Color(0xFF212121)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.01;
      canvas.drawLine(
        Offset(cx - headR * 0.35 + glassR, glassY),
        Offset(cx + headR * 0.35 - glassR, glassY),
        bridgePaint,
      );
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
        ..quadraticBezierTo(cx, bodyTop + s * 0.07, cx + s * 0.04, bodyTop + s * 0.01);
      canvas.drawPath(chainPath, chainPaint);
    }

    // ── Earring accessory ──
    if (config.accessories.contains('earring')) {
      final earPaint = Paint()..color = const Color(0xFFFFD54F);
      canvas.drawCircle(Offset(cx - headR * 1.0, headCy + headR * 0.1), s * 0.015, earPaint);
    }
  }

  void _drawHair(Canvas canvas, double cx, double cy, double r, Paint paint) {
    switch (config.hairStyle) {
      case 0: // Short
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.08),
          3.4, 2.5, true, paint,
        );
        break;
      case 1: // Medium
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.12),
          3.0, 3.3, true, paint,
        );
        // Side hair
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - r * 1.15, cy - r * 0.2, r * 0.25, r * 1.0),
          Radius.circular(r * 0.1),
        ), paint);
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + r * 0.9, cy - r * 0.2, r * 0.25, r * 1.0),
          Radius.circular(r * 0.1),
        ), paint);
        break;
      case 2: // Long
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.12),
          3.0, 3.3, true, paint,
        );
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - r * 1.15, cy - r * 0.2, r * 0.3, r * 1.8),
          Radius.circular(r * 0.12),
        ), paint);
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + r * 0.85, cy - r * 0.2, r * 0.3, r * 1.8),
          Radius.circular(r * 0.12),
        ), paint);
        break;
      case 3: // Buzz
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.03),
          3.6, 2.0, true, paint,
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
    }
  }

  double _cos(double a) => a == 0 ? 1 : (a * 0.017453292519943).cosOf();
  double _sin(double a) => a == 0 ? 0 : (a * 0.017453292519943).sinOf();

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.isWalking != isWalking;
  }
}

// Extension to avoid importing dart:math everywhere in the painter
extension _TrigExt on double {
  double cosOf() {
    // Taylor approximation replaced by dart:math
    return _cosVal(this);
  }

  double sinOf() {
    return _sinVal(this);
  }
}

double _cosVal(double rad) {
  // Use identity
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
