import 'auth_service.dart';
import 'avatar_service.dart';
import 'local_data_service.dart';

/// User preferences - local first, cached in memory + persisted in SharedPreferences.
class UserPreferencesService {
  static final UserPreferencesService _instance = UserPreferencesService._();
  factory UserPreferencesService() => _instance;
  UserPreferencesService._();

  String? name;
  String? ageGroup;
  List<String> concerns = <String>[];
  String? sleepSchedule;
  double moodBaseline = 0.5;
  String communityPreference = 'yes';
  List<String> musicLanguages = <String>[];

  late String avatarSeed = AvatarService().generateRandomSeed();
  late String avatarStyle = AvatarService().getRandomStyle();

  bool get hasMusicSetup => musicLanguages.isNotEmpty;
  bool get hasCompletedOnboarding => name != null && name!.isNotEmpty;
  String get displayName => name ?? 'friend';

  String getAvatarUrl() {
    return AvatarService().getAvatarUrl(seed: avatarSeed, style: avatarStyle);
  }

  void regenerateAvatar() {
    avatarSeed = AvatarService().generateRandomSeed();
  }

  void setAvatarStyle(String style) {
    avatarStyle = style;
  }

  Future<void> loadFromRemote() async {
    await loadFromLocal();
  }

  Future<void> saveToRemote() async {
    await saveToLocal();
  }

  Future<void> loadFromLocal() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    await LocalDataService().init();
    final data = LocalDataService().getUserPrefs(user.$id);
    name = data['name'] as String?;
    ageGroup = data['ageGroup'] as String?;
    concerns = (data['concerns'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();
    sleepSchedule = data['sleepSchedule'] as String?;
    moodBaseline = (data['moodBaseline'] as num?)?.toDouble() ?? 0.5;
    communityPreference = (data['communityPreference'] as String?) ?? 'yes';
    musicLanguages = (data['musicLanguages'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();
    avatarSeed = (data['avatarSeed'] as String?) ?? avatarSeed;
    avatarStyle = (data['avatarStyle'] as String?) ?? avatarStyle;
  }

  Future<void> saveToLocal() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    await LocalDataService().init();
    await LocalDataService().saveUserPrefs(user.$id, <String, dynamic>{
      'name': name,
      'ageGroup': ageGroup,
      'concerns': concerns,
      'sleepSchedule': sleepSchedule,
      'moodBaseline': moodBaseline,
      'communityPreference': communityPreference,
      'musicLanguages': musicLanguages,
      'avatarSeed': avatarSeed,
      'avatarStyle': avatarStyle,
      'avatarUrl': getAvatarUrl(),
    });
    await LocalDataService().addAnalytics(
      'user_prefs_saved',
      payload: <String, dynamic>{'userId': user.$id},
    );
  }
}

