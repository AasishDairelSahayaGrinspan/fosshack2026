import 'package:flutter/material.dart';
import 'dart:math';

class AvatarConfig {
  final int bodyType; // 0=slim, 1=average, 2=broad
  final Color skinColor;
  final int
  hairStyle; // 0=short, 1=medium, 2=long, 3=buzz, 4=curly, 5=ponytail, 6=braids, 7=afro, 8=bald
  final Color hairColor;
  final int
  shirtStyle; // 0=tee, 1=hoodie, 2=tank, 3=formal, 4=jacket, 5=crop top
  final Color shirtColor;
  final int pantsStyle; // 0=jeans, 1=shorts, 2=joggers
  final Color pantsColor;
  final int shoeStyle; // 0=sneakers, 1=boots, 2=sandals
  final Color shoeColor;
  final List<String>
  accessories; // 'sunglasses', 'chain', 'hat', 'earring', 'watch', 'backpack', 'headband', 'glassesRound', 'glassesSquare'
  final int eyeStyle; // 0=round, 1=almond, 2=narrow, 3=wide, 4=sleepy
  final int smileStyle; // 0=happy, 1=neutral, 2=smirk, 3=gentle

  const AvatarConfig({
    this.bodyType = 1,
    this.skinColor = const Color(0xFFF5CBA7),
    this.hairStyle = 0,
    this.hairColor = const Color(0xFF3E2723),
    this.shirtStyle = 0,
    this.shirtColor = const Color(0xFF7986CB),
    this.pantsStyle = 0,
    this.pantsColor = const Color(0xFF455A64),
    this.shoeStyle = 0,
    this.shoeColor = const Color(0xFFEEEEEE),
    this.accessories = const [],
    this.eyeStyle = 0,
    this.smileStyle = 0,
  });

  AvatarConfig copyWith({
    int? bodyType,
    Color? skinColor,
    int? hairStyle,
    Color? hairColor,
    int? shirtStyle,
    Color? shirtColor,
    int? pantsStyle,
    Color? pantsColor,
    int? shoeStyle,
    Color? shoeColor,
    List<String>? accessories,
    int? eyeStyle,
    int? smileStyle,
  }) {
    return AvatarConfig(
      bodyType: bodyType ?? this.bodyType,
      skinColor: skinColor ?? this.skinColor,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      shirtStyle: shirtStyle ?? this.shirtStyle,
      shirtColor: shirtColor ?? this.shirtColor,
      pantsStyle: pantsStyle ?? this.pantsStyle,
      pantsColor: pantsColor ?? this.pantsColor,
      shoeStyle: shoeStyle ?? this.shoeStyle,
      shoeColor: shoeColor ?? this.shoeColor,
      accessories: accessories ?? this.accessories,
      eyeStyle: eyeStyle ?? this.eyeStyle,
      smileStyle: smileStyle ?? this.smileStyle,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bodyType': bodyType,
      'skinColor': skinColor.toARGB32(),
      'hairStyle': hairStyle,
      'hairColor': hairColor.toARGB32(),
      'shirtStyle': shirtStyle,
      'shirtColor': shirtColor.toARGB32(),
      'pantsStyle': pantsStyle,
      'pantsColor': pantsColor.toARGB32(),
      'shoeStyle': shoeStyle,
      'shoeColor': shoeColor.toARGB32(),
      'accessories': accessories,
      'eyeStyle': eyeStyle,
      'smileStyle': smileStyle,
    };
  }

  factory AvatarConfig.fromMap(Map<String, dynamic> map) {
    return AvatarConfig(
      bodyType: (map['bodyType'] as num?)?.toInt() ?? 1,
      skinColor: Color(map['skinColor'] as int? ?? 0xFFF5CBA7),
      hairStyle: (map['hairStyle'] as num?)?.toInt() ?? 0,
      hairColor: Color(map['hairColor'] as int? ?? 0xFF3E2723),
      shirtStyle: (map['shirtStyle'] as num?)?.toInt() ?? 0,
      shirtColor: Color(map['shirtColor'] as int? ?? 0xFF7986CB),
      pantsStyle: (map['pantsStyle'] as num?)?.toInt() ?? 0,
      pantsColor: Color(map['pantsColor'] as int? ?? 0xFF455A64),
      shoeStyle: (map['shoeStyle'] as num?)?.toInt() ?? 0,
      shoeColor: Color(map['shoeColor'] as int? ?? 0xFFEEEEEE),
      accessories:
          (map['accessories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      eyeStyle: (map['eyeStyle'] as num?)?.toInt() ?? 0,
      smileStyle: (map['smileStyle'] as num?)?.toInt() ?? 0,
    );
  }

  /// Convert to JSON string for storage
  String toJsonString() {
    return _toJsonStringHelper(toMap());
  }

  static String _toJsonStringHelper(Map<String, dynamic> map) {
    final buffer = StringBuffer('{');
    bool first = true;
    for (final entry in map.entries) {
      if (!first) buffer.write(',');
      buffer.write('"${entry.key}":');
      if (entry.value is String) {
        buffer.write('"${entry.value}"');
      } else if (entry.value is List) {
        buffer.write('[${(entry.value as List).join(',')}]');
      } else {
        buffer.write(entry.value);
      }
      first = false;
    }
    buffer.write('}');
    return buffer.toString();
  }

  /// Create from JSON string
  static AvatarConfig fromJsonString(String json) {
    final startIdx = json.indexOf('{');
    final endIdx = json.lastIndexOf('}');
    if (startIdx == -1 || endIdx == -1) {
      return const AvatarConfig();
    }
    // Simple JSON parsing - convert to map
    final mapStr = json.substring(startIdx + 1, endIdx);
    final map = <String, dynamic>{};
    for (final part in mapStr.split(',')) {
      if (part.trimRight().isEmpty) continue;
      final kv = part.split(':');
      if (kv.length == 2) {
        final key = kv[0].trim().replaceAll('"', '');
        final value = kv[1].trim().replaceAll('"', '');
        // Simple parsing - enough for this use case
        if (key == 'accessories') {
          map[key] = value.startsWith('[')
              ? value.substring(1, value.length - 1).split(',')
              : [];
        } else {
          final intVal = int.tryParse(value);
          if (intVal != null) {
            map[key] = intVal;
          }
        }
      }
    }
    return AvatarConfig.fromMap(map);
  }

  /// Create a random avatar configuration
  static AvatarConfig random() {
    final random = Random();
    final colors = [
      const Color(0xFFF5CBA7),
      const Color(0xFFE0B59A),
      const Color(0xFFC5886A),
      const Color(0xFF8D6E63),
      const Color(0xFF6D4C41),
    ];
    final shirtColors = [
      const Color(0xFF7986CB),
      const Color(0xFFFFA726),
      const Color(0xFF66BB6A),
      const Color(0xFFEF5350),
      const Color(0xFFAB47BC),
    ];

    return AvatarConfig(
      bodyType: random.nextInt(3),
      skinColor: colors[random.nextInt(colors.length)],
      hairStyle: random.nextInt(9),
      hairColor: colors[random.nextInt(colors.length)],
      shirtStyle: random.nextInt(6),
      shirtColor: shirtColors[random.nextInt(shirtColors.length)],
      pantsStyle: random.nextInt(3),
      pantsColor: const Color(0xFF455A64),
      shoeStyle: random.nextInt(3),
      shoeColor: const Color(0xFFEEEEEE),
      accessories: [],
      eyeStyle: random.nextInt(5),
      smileStyle: random.nextInt(4),
    );
  }

  // Getters and setters for properties (used in avatar customization)
  int get presentation => bodyType;

  int get faceShape => eyeStyle;

  int get skinTone => 0; // Derived from skinColor

  int get mouthStyle => smileStyle;

  int get accessory => accessories.isNotEmpty ? 1 : 0;

  int get clothing => shirtStyle;

  int get clothingColor => 0; // Simplified for compatibility

  static const List<Color> skinColors = [
    Color(0xFFFDE7C8), // fair
    Color(0xFFF5CBA7), // light
    Color(0xFFD4A574), // medium
    Color(0xFFA0724A), // tan
    Color(0xFF6B4226), // brown
    Color(0xFF3E2115), // dark
  ];

  static const List<Color> hairColors = [
    Color(0xFF1A1A1A), // black
    Color(0xFF3E2723), // dark brown
    Color(0xFF795548), // brown
    Color(0xFFD4A574), // blonde
    Color(0xFFB71C1C), // red
    Color(0xFF7986CB), // blue (fun)
    Color(0xFFEC407A), // pink (fun)
  ];

  static const List<Color> shirtColors = [
    Color(0xFF7986CB), // indigo
    Color(0xFFEF5350), // red
    Color(0xFF66BB6A), // green
    Color(0xFFFFCA28), // yellow
    Color(0xFF42A5F5), // blue
    Color(0xFFAB47BC), // purple
    Color(0xFFEEEEEE), // white
    Color(0xFF212121), // black
  ];

  static const List<Color> pantsColors = [
    Color(0xFF455A64), // dark blue
    Color(0xFF212121), // black
    Color(0xFF795548), // brown
    Color(0xFF37474F), // charcoal
    Color(0xFF1565C0), // blue jeans
    Color(0xFFBDBDBD), // grey
  ];

  static const List<Color> shoeColors = [
    Color(0xFFEEEEEE), // white
    Color(0xFF212121), // black
    Color(0xFFEF5350), // red
    Color(0xFF42A5F5), // blue
    Color(0xFF66BB6A), // green
  ];

  static const List<String> hairStyleNames = [
    'Short',
    'Medium',
    'Long',
    'Buzz',
    'Curly',
    'Ponytail',
    'Braids',
    'Afro',
    'Bald',
  ];

  static const List<String> shirtStyleNames = [
    'T-Shirt',
    'Hoodie',
    'Tank',
    'Formal',
    'Jacket',
    'Crop Top',
  ];

  static const List<String> pantsStyleNames = ['Jeans', 'Shorts', 'Joggers'];
  static const List<String> shoeStyleNames = ['Sneakers', 'Boots', 'Sandals'];

  static const List<String> eyeStyleNames = [
    'Round',
    'Almond',
    'Narrow',
    'Wide',
    'Sleepy',
  ];

  static const List<String> smileStyleNames = [
    'Happy',
    'Neutral',
    'Smirk',
    'Gentle',
  ];

  static const List<String> accessoryNames = [
    'sunglasses',
    'chain',
    'hat',
    'earring',
    'watch',
    'backpack',
    'headband',
    'glassesRound',
    'glassesSquare',
  ];
}
