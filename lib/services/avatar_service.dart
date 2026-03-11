import 'dart:math';

class AvatarService {
  static final AvatarService _instance = AvatarService._();
  factory AvatarService() => _instance;
  AvatarService._();

  // Available avatar styles from DiceBear
  static const List<String> avatarStyles = [
    'avataaars',
    'avataaars-neutral',
    'bits',
    'big-ears',
    'big-ears-neutral',
    'big-smile',
    'bottts',
    'bottts-neutral',
    'crackers',
    'croodles',
    'croodles-neutral',
    'fun-emoji',
    'icons',
    'identicon',
    'initials',
    'miniavs',
    'notionists',
    'notionists-neutral',
    'personas',
    'pixel-art',
    'pixel-art-neutral',
    'rings',
    'shapes',
    'thumbs',
  ];

  /// Generates a random seed for avatar uniqueness
  String generateRandomSeed() {
    final random = Random();
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Gets a random avatar style
  String getRandomStyle() {
    return avatarStyles[Random().nextInt(avatarStyles.length)];
  }

  /// Generates the DiceBear API URL for an avatar
  ///
  /// Parameters:
  /// - [style]: The avatar style (defaults to random style)
  /// - [seed]: The unique seed for avatar generation
  /// - [scale]: Size scale for the avatar (optional)
  /// - [backgroundColor]: Background color in hex (optional)
  String getAvatarUrl({
    required String seed,
    required String style,
    double scale = 100,
    String? backgroundColor,
  }) {
    final baseUrl = 'https://api.dicebear.com/9.x/$style/png';
    final params = <String, String>{
      'seed': seed,
      'scale': scale.toStringAsFixed(0),
    };

    if (backgroundColor != null) {
      params['backgroundColor'] = backgroundColor;
    }

    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    return '$baseUrl?$queryString';
  }

  /// Gets a list of recommended styles for initial selection
  static List<String> getRecommendedStyles() {
    return const ['avataaars', 'big-smile', 'croodles', 'pixel-art', 'shapes'];
  }
}
