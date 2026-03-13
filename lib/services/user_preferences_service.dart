import 'database_service.dart';
import 'auth_service.dart';
import 'avatar_service.dart';

/// User preferences — loads from Appwrite, falls back to in-memory.
class UserPreferencesService {
  static final UserPreferencesService _instance = UserPreferencesService._();
  factory UserPreferencesService() => _instance;
  UserPreferencesService._();

  String? name;
  String? ageGroup;
  List<String> concerns = [];
  String? sleepSchedule;
  double moodBaseline = 0.5;
  List<String> musicLanguages = [];

  // Avatar config (DiceBear)
  late String avatarSeed = AvatarService().generateRandomSeed();
  late String avatarStyle = AvatarService().getRandomStyle();

  bool get hasCompletedOnboarding => name != null && name!.isNotEmpty;

  String get displayName => name ?? 'friend';

  /// Gets the avatar URL for this user
  String getAvatarUrl() {
    return AvatarService().getAvatarUrl(seed: avatarSeed, style: avatarStyle);
  }

  /// Regenerates a new random avatar
  void regenerateAvatar() {
    avatarSeed = AvatarService().generateRandomSeed();
  }

  /// Changes the avatar style
  void setAvatarStyle(String style) {
    avatarStyle = style;
  }

  /// Load user profile from Appwrite database.
  Future<void> loadFromRemote() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    try {
      final doc = await DatabaseService().getUserProfile(user.$id);
      final data = doc.data;
      name = data['name'];
      ageGroup = data['ageGroup'];
      concerns = List<String>.from(data['concerns'] ?? []);
      sleepSchedule = data['sleepSchedule'];
      moodBaseline = (data['moodBaseline'] as num?)?.toDouble() ?? 0.5;
      musicLanguages = List<String>.from(data['musicLanguages'] ?? []);
      if (data['avatarUrl'] != null) {
        // Parse seed and style from stored URL if available
        // Otherwise keep the randomly generated defaults
      }
    } catch (_) {
      // Profile not created yet — keep defaults
    }
  }

  /// Save current preferences to Appwrite.
  Future<void> saveToRemote() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    try {
      // Try update first
      await DatabaseService().updateUserProfile(user.$id, {
        'name': name,
        'ageGroup': ageGroup,
        'concerns': concerns,
        'sleepSchedule': sleepSchedule,
        'moodBaseline': moodBaseline,
        'avatarUrl': getAvatarUrl(),
        'musicLanguages': musicLanguages,
      });
    } catch (_) {
      // If profile doesn't exist, create it
      try {
        await DatabaseService().createUserProfile(
          userId: user.$id,
          name: name ?? 'friend',
          ageGroup: ageGroup,
          concerns: concerns,
          sleepSchedule: sleepSchedule,
          moodBaseline: moodBaseline,
          avatarUrl: getAvatarUrl(),
        );
      } catch (_) {
        // Permission denied or network error — continue with local defaults
      }
    }
  }
}
