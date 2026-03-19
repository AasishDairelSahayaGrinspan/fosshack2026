import 'dart:convert';
import 'dart:math';

/// Configuration for the custom Snapchat-like avatar system.
/// Each field indexes into a list of predefined options.
class AvatarConfig {
  int presentation; // 0=female, 1=male
  int faceShape; // 0-5 options
  int skinTone; // 0-7 (predefined hex colors)
  int hairStyle; // 0-15 styles
  int hairColor; // 0-9 colors
  int eyeStyle; // 0-8 styles
  int mouthStyle; // 0-6 styles
  int accessory; // 0-5 (none, glasses, sunglasses, earrings, headband, hat)
  int clothing; // 0-8 styles
  int clothingColor; // 0-7 colors

  AvatarConfig({
    this.presentation = 0,
    this.faceShape = 0,
    this.skinTone = 2,
    this.hairStyle = 0,
    this.hairColor = 0,
    this.eyeStyle = 0,
    this.mouthStyle = 0,
    this.accessory = 0,
    this.clothing = 0,
    this.clothingColor = 0,
  });

  /// Generate a random avatar config.
  factory AvatarConfig.random() {
    final rng = Random();
    final presentation = rng.nextBool() ? 1 : 0;
    final hairPool = presentation == 1
        ? AvatarHairPools.masculine
        : AvatarHairPools.feminine;
    return AvatarConfig(
      presentation: presentation,
      faceShape: rng.nextInt(6),
      skinTone: rng.nextInt(8),
      hairStyle: hairPool[rng.nextInt(hairPool.length)],
      hairColor: rng.nextInt(10),
      eyeStyle: rng.nextInt(9),
      mouthStyle: rng.nextInt(7),
      accessory: rng.nextInt(6),
      clothing: rng.nextInt(9),
      clothingColor: rng.nextInt(8),
    );
  }

  factory AvatarConfig.fromJson(Map<String, dynamic> json) {
    return AvatarConfig(
      presentation: (json['presentation'] as num?)?.toInt() ?? 0,
      faceShape: (json['faceShape'] as num?)?.toInt() ?? 0,
      skinTone: (json['skinTone'] as num?)?.toInt() ?? 2,
      hairStyle: (json['hairStyle'] as num?)?.toInt() ?? 0,
      hairColor: (json['hairColor'] as num?)?.toInt() ?? 0,
      eyeStyle: (json['eyeStyle'] as num?)?.toInt() ?? 0,
      mouthStyle: (json['mouthStyle'] as num?)?.toInt() ?? 0,
      accessory: (json['accessory'] as num?)?.toInt() ?? 0,
      clothing: (json['clothing'] as num?)?.toInt() ?? 0,
      clothingColor: (json['clothingColor'] as num?)?.toInt() ?? 0,
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

  Map<String, dynamic> toJson() => {
      'presentation': presentation,
        'faceShape': faceShape,
        'skinTone': skinTone,
        'hairStyle': hairStyle,
        'hairColor': hairColor,
        'eyeStyle': eyeStyle,
        'mouthStyle': mouthStyle,
        'accessory': accessory,
        'clothing': clothing,
        'clothingColor': clothingColor,
      };

  String toJsonString() => jsonEncode(toJson());

  AvatarConfig copyWith({
    int? presentation,
    int? faceShape,
    int? skinTone,
    int? hairStyle,
    int? hairColor,
    int? eyeStyle,
    int? mouthStyle,
    int? accessory,
    int? clothing,
    int? clothingColor,
  }) {
    return AvatarConfig(
      presentation: presentation ?? this.presentation,
      faceShape: faceShape ?? this.faceShape,
      skinTone: skinTone ?? this.skinTone,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      eyeStyle: eyeStyle ?? this.eyeStyle,
      mouthStyle: mouthStyle ?? this.mouthStyle,
      accessory: accessory ?? this.accessory,
      clothing: clothing ?? this.clothing,
      clothingColor: clothingColor ?? this.clothingColor,
    );
  }
}

class AvatarHairPools {
  AvatarHairPools._();

  static const List<int> feminine = [5, 6, 7, 8, 10, 12, 13, 14, 9, 15, 4, 0];
  static const List<int> masculine = [0, 1, 2, 3, 4, 9, 10, 11, 12, 15, 14, 5];
}
