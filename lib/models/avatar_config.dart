import 'package:flutter/material.dart';

class AvatarConfig {
  final int bodyType; // 0=slim, 1=average, 2=broad
  final Color skinColor;
  final int hairStyle; // 0=short, 1=medium, 2=long, 3=buzz, 4=curly
  final Color hairColor;
  final int shirtStyle; // 0=tee, 1=hoodie, 2=tank
  final Color shirtColor;
  final int pantsStyle; // 0=jeans, 1=shorts, 2=joggers
  final Color pantsColor;
  final int shoeStyle; // 0=sneakers, 1=boots, 2=sandals
  final Color shoeColor;
  final List<String> accessories; // 'sunglasses', 'chain', 'hat', 'earring'

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
      accessories: (map['accessories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

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
  ];

  static const List<String> shirtStyleNames = ['T-Shirt', 'Hoodie', 'Tank'];
  static const List<String> pantsStyleNames = ['Jeans', 'Shorts', 'Joggers'];
  static const List<String> shoeStyleNames = ['Sneakers', 'Boots', 'Sandals'];
  static const List<String> accessoryNames = [
    'sunglasses',
    'chain',
    'hat',
    'earring',
  ];
}
