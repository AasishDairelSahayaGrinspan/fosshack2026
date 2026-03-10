import 'database_service.dart';
import 'auth_service.dart';

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

  // Avatar config
  int hairStyle = 0;
  int skinTone = 0;
  int outfitColor = 0;

  bool get hasCompletedOnboarding => name != null && name!.isNotEmpty;

  String get displayName => name ?? 'friend';

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
      hairStyle = data['hairStyle'] ?? 0;
      skinTone = data['skinTone'] ?? 0;
      outfitColor = data['outfitColor'] ?? 0;
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
        'hairStyle': hairStyle,
        'skinTone': skinTone,
        'outfitColor': outfitColor,
      });
    } catch (_) {
      // If profile doesn't exist, create it
      await DatabaseService().createUserProfile(
        userId: user.$id,
        name: name ?? 'friend',
        ageGroup: ageGroup,
        concerns: concerns,
        sleepSchedule: sleepSchedule,
        moodBaseline: moodBaseline,
        hairStyle: hairStyle,
        skinTone: skinTone,
        outfitColor: outfitColor,
      );
    }
  }
}
