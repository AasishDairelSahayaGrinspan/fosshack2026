import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

/// Hybrid avatar config used by both:
/// 1) index-based avatar editor/renderer (presentation/skinTone/etc), and
/// 2) legacy color-based avatar renderer (skinColor/shirtColor/etc).
class AvatarConfig {
  // Index-based fields.
  int presentation;
  int faceShape;
  int skinTone;
  int hairStyle;
  dynamic hairColor; // int index for new renderer, Color for legacy renderer.
  int eyeStyle;
  int mouthStyle;
  int smileStyle;
  int accessory;
  int clothing;
  int clothingColor;

  // Legacy color-based fields.
  int bodyType;
  Color skinColor;
  int shirtStyle;
  Color shirtColor;
  int pantsStyle;
  Color pantsColor;
  int shoeStyle;
  Color shoeColor;
  List<String> accessories;

  AvatarConfig({
    this.presentation = 0,
    this.faceShape = 0,
    this.skinTone = 2,
    this.hairStyle = 0,
    this.hairColor = 0,
    this.eyeStyle = 0,
    this.mouthStyle = 0,
    this.smileStyle = 0,
    this.accessory = 0,
    this.clothing = 0,
    this.clothingColor = 0,
    this.bodyType = 1,
    this.skinColor = const Color(0xFFF5CBA7),
    this.shirtStyle = 0,
    this.shirtColor = const Color(0xFF7986CB),
    this.pantsStyle = 0,
    this.pantsColor = const Color(0xFF455A64),
    this.shoeStyle = 0,
    this.shoeColor = const Color(0xFFEEEEEE),
    this.accessories = const <String>[],
  });

  factory AvatarConfig.random() {
    final rng = Random();
    final p = rng.nextBool() ? 1 : 0;
    final hairPool = p == 1 ? AvatarHairPools.masculine : AvatarHairPools.feminine;
    final skinTone = rng.nextInt(8);
    final hairColorIndex = rng.nextInt(10);
    final clothingColor = rng.nextInt(8);

    return AvatarConfig(
      presentation: p,
      faceShape: rng.nextInt(6),
      skinTone: skinTone,
      hairStyle: hairPool[rng.nextInt(hairPool.length)],
      hairColor: hairColorIndex,
      eyeStyle: rng.nextInt(9),
      mouthStyle: rng.nextInt(7),
      smileStyle: rng.nextInt(4),
      accessory: rng.nextInt(6),
      clothing: rng.nextInt(9),
      clothingColor: clothingColor,
      bodyType: rng.nextInt(3),
      skinColor: _skinTonePalette[skinTone.clamp(0, _skinTonePalette.length - 1)],
      shirtStyle: rng.nextInt(6),
      shirtColor: _clothingColorPalette[clothingColor.clamp(0, _clothingColorPalette.length - 1)],
      pantsStyle: rng.nextInt(3),
      pantsColor: const Color(0xFF455A64),
      shoeStyle: rng.nextInt(3),
      shoeColor: const Color(0xFFEEEEEE),
      accessories: const <String>[],
    );
  }

  factory AvatarConfig.fromJson(Map<String, dynamic> json) {
    final skinTone = (json['skinTone'] as num?)?.toInt() ?? 2;
    final clothingColor = (json['clothingColor'] as num?)?.toInt() ?? 0;

    return AvatarConfig(
      presentation: (json['presentation'] as num?)?.toInt() ?? 0,
      faceShape: (json['faceShape'] as num?)?.toInt() ?? 0,
      skinTone: skinTone,
      hairStyle: (json['hairStyle'] as num?)?.toInt() ?? 0,
      hairColor: (json['hairColor'] as num?)?.toInt() ?? 0,
      eyeStyle: (json['eyeStyle'] as num?)?.toInt() ?? 0,
      mouthStyle: (json['mouthStyle'] as num?)?.toInt() ?? 0,
        smileStyle: (json['smileStyle'] as num?)?.toInt() ??
          ((json['mouthStyle'] as num?)?.toInt() ?? 0),
      accessory: (json['accessory'] as num?)?.toInt() ?? 0,
      clothing: (json['clothing'] as num?)?.toInt() ?? 0,
      clothingColor: clothingColor,
      bodyType: (json['bodyType'] as num?)?.toInt() ?? 1,
      skinColor: _skinTonePalette[skinTone.clamp(0, _skinTonePalette.length - 1)],
      shirtStyle: (json['shirtStyle'] as num?)?.toInt() ?? 0,
      shirtColor: _clothingColorPalette[
          clothingColor.clamp(0, _clothingColorPalette.length - 1)],
      pantsStyle: (json['pantsStyle'] as num?)?.toInt() ?? 0,
      pantsColor: const Color(0xFF455A64),
      shoeStyle: (json['shoeStyle'] as num?)?.toInt() ?? 0,
      shoeColor: const Color(0xFFEEEEEE),
      accessories: const <String>[],
    );
  }

  factory AvatarConfig.fromJsonString(String jsonString) {
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return AvatarConfig.fromJson(map);
    } catch (_) {
      return AvatarConfig();
    }
  }

  /// Legacy map loader for color-based avatar usage.
  factory AvatarConfig.fromMap(Map<String, dynamic> map) {
    return AvatarConfig(
      bodyType: (map['bodyType'] as num?)?.toInt() ?? 1,
      skinColor: Color((map['skinColor'] as int?) ?? 0xFFF5CBA7),
      hairStyle: (map['hairStyle'] as num?)?.toInt() ?? 0,
      hairColor: Color((map['hairColor'] as int?) ?? 0xFF3E2723),
      shirtStyle: (map['shirtStyle'] as num?)?.toInt() ?? 0,
      shirtColor: Color((map['shirtColor'] as int?) ?? 0xFF7986CB),
      pantsStyle: (map['pantsStyle'] as num?)?.toInt() ?? 0,
      pantsColor: Color((map['pantsColor'] as int?) ?? 0xFF455A64),
      shoeStyle: (map['shoeStyle'] as num?)?.toInt() ?? 0,
      shoeColor: Color((map['shoeColor'] as int?) ?? 0xFFEEEEEE),
      accessories: (map['accessories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
    );
  }

  Map<String, dynamic> toJson() => {
        'presentation': presentation,
        'faceShape': faceShape,
        'skinTone': skinTone,
        'hairStyle': hairStyle,
        'hairColor': hairColor is int ? hairColor as int : 0,
        'eyeStyle': eyeStyle,
        'mouthStyle': mouthStyle,
        'smileStyle': smileStyle,
        'accessory': accessory,
        'clothing': clothing,
        'clothingColor': clothingColor,
        'bodyType': bodyType,
        'shirtStyle': shirtStyle,
        'pantsStyle': pantsStyle,
        'shoeStyle': shoeStyle,
      };

  String toJsonString() => jsonEncode(toJson());

  Map<String, dynamic> toMap() => {
        'bodyType': bodyType,
        'skinColor': skinColor.toARGB32(),
        'hairStyle': hairStyle,
        'hairColor': (hairColor is Color)
            ? (hairColor as Color).toARGB32()
            : const Color(0xFF3E2723).toARGB32(),
        'shirtStyle': shirtStyle,
        'shirtColor': shirtColor.toARGB32(),
        'pantsStyle': pantsStyle,
        'pantsColor': pantsColor.toARGB32(),
        'shoeStyle': shoeStyle,
        'shoeColor': shoeColor.toARGB32(),
        'accessories': accessories,
      };

  AvatarConfig copyWith({
    int? presentation,
    int? faceShape,
    int? skinTone,
    int? hairStyle,
    dynamic hairColor,
    int? eyeStyle,
    int? mouthStyle,
    int? smileStyle,
    int? accessory,
    int? clothing,
    int? clothingColor,
    int? bodyType,
    Color? skinColor,
    int? shirtStyle,
    Color? shirtColor,
    int? pantsStyle,
    Color? pantsColor,
    int? shoeStyle,
    Color? shoeColor,
    List<String>? accessories,
  }) {
    return AvatarConfig(
      presentation: presentation ?? this.presentation,
      faceShape: faceShape ?? this.faceShape,
      skinTone: skinTone ?? this.skinTone,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      eyeStyle: eyeStyle ?? this.eyeStyle,
      mouthStyle: mouthStyle ?? this.mouthStyle,
      smileStyle: smileStyle ?? this.smileStyle,
      accessory: accessory ?? this.accessory,
      clothing: clothing ?? this.clothing,
      clothingColor: clothingColor ?? this.clothingColor,
      bodyType: bodyType ?? this.bodyType,
      skinColor: skinColor ?? this.skinColor,
      shirtStyle: shirtStyle ?? this.shirtStyle,
      shirtColor: shirtColor ?? this.shirtColor,
      pantsStyle: pantsStyle ?? this.pantsStyle,
      pantsColor: pantsColor ?? this.pantsColor,
      shoeStyle: shoeStyle ?? this.shoeStyle,
      shoeColor: shoeColor ?? this.shoeColor,
      accessories: accessories ?? this.accessories,
    );
  }
}

class AvatarHairPools {
  AvatarHairPools._();

  static const List<int> feminine = [5, 6, 7, 8, 10, 12, 13, 14, 9, 15, 4, 0];
  static const List<int> masculine = [0, 1, 2, 3, 4, 9, 10, 11, 12, 15, 14, 5];
}

const List<Color> _skinTonePalette = <Color>[
  Color(0xFFFDE7C8),
  Color(0xFFF5CBA7),
  Color(0xFFD4A574),
  Color(0xFFC18A5A),
  Color(0xFFA86A3D),
  Color(0xFF8D5524),
  Color(0xFF6B4226),
  Color(0xFF3E2723),
];

const List<Color> _clothingColorPalette = <Color>[
  Color(0xFF7986CB),
  Color(0xFFEF5350),
  Color(0xFF66BB6A),
  Color(0xFFFFCA28),
  Color(0xFF42A5F5),
  Color(0xFFAB47BC),
  Color(0xFFEEEEEE),
  Color(0xFF212121),
];
