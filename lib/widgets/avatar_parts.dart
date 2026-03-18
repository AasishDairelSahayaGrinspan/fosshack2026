import 'dart:ui';

/// Predefined avatar part data for the layered 2D avatar system.
/// All colors and measurements used by AvatarRenderer.

class AvatarParts {
  AvatarParts._();

  // ─── Skin Tones (8 options) ───
  static const List<Color> skinTones = [
    Color(0xFFFDEBD0), // Very light
    Color(0xFFF5D5B8), // Light
    Color(0xFFE8B88A), // Light-medium
    Color(0xFFD4956B), // Medium
    Color(0xFFC68642), // Medium-tan
    Color(0xFFA06633), // Tan
    Color(0xFF8D5524), // Dark
    Color(0xFF5C3317), // Very dark
  ];

  // ─── Hair Colors (10 options) ───
  static const List<Color> hairColors = [
    Color(0xFF2C1B18), // Black
    Color(0xFF4A3322), // Dark brown
    Color(0xFF6B4226), // Brown
    Color(0xFF8B6B3D), // Light brown
    Color(0xFFB8860B), // Dark blonde
    Color(0xFFDAA520), // Blonde
    Color(0xFFF5DEB3), // Platinum
    Color(0xFFCC3333), // Red
    Color(0xFF8B4513), // Auburn
    Color(0xFF808080), // Gray
  ];

  // ─── Clothing Colors (8 options) ───
  static const List<Color> clothingColors = [
    Color(0xFF6C5B7B), // Indigo/Purple
    Color(0xFF355C7D), // Navy
    Color(0xFF2E8B57), // Green
    Color(0xFFC06C84), // Rose
    Color(0xFFF67280), // Coral
    Color(0xFFF8B500), // Gold
    Color(0xFF3D3D3D), // Charcoal
    Color(0xFFE8E8E8), // Light gray
  ];

  // ─── Face Shape Names ───
  static const List<String> faceShapeNames = [
    'Oval',
    'Round',
    'Heart',
    'Square',
    'Long',
    'Diamond',
  ];

  // ─── Hair Style Names (16 styles) ───
  static const List<String> hairStyleNames = [
    'Short Crop',
    'Buzz Cut',
    'Side Part',
    'Slick Back',
    'Messy',
    'Long Straight',
    'Long Wavy',
    'Bob',
    'Pixie',
    'Afro',
    'Curly',
    'Mohawk',
    'Braids',
    'Bun',
    'Ponytail',
    'Bald',
  ];

  // ─── Eye Style Names (9 styles) ───
  static const List<String> eyeStyleNames = [
    'Normal',
    'Happy',
    'Surprised',
    'Sleepy',
    'Wink',
    'Cat',
    'Round',
    'Narrow',
    'Lashes',
  ];

  // ─── Mouth Style Names (7 styles) ───
  static const List<String> mouthStyleNames = [
    'Smile',
    'Grin',
    'Neutral',
    'Slight Smile',
    'Open',
    'Pout',
    'Tongue',
  ];

  // ─── Accessory Names (6 options) ───
  static const List<String> accessoryNames = [
    'None',
    'Glasses',
    'Sunglasses',
    'Earrings',
    'Headband',
    'Hat',
  ];

  // ─── Clothing Style Names (9 styles) ───
  static const List<String> clothingStyleNames = [
    'T-Shirt',
    'V-Neck',
    'Crew Neck',
    'Hoodie',
    'Collared',
    'Tank Top',
    'Sweater',
    'Jacket',
    'Turtleneck',
  ];
}
