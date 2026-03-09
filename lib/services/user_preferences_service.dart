/// In-memory user preferences from onboarding.
class UserPreferencesService {
  static final UserPreferencesService _instance = UserPreferencesService._();
  factory UserPreferencesService() => _instance;
  UserPreferencesService._();

  String? name;
  String? ageGroup;
  List<String> concerns = [];
  String? sleepSchedule; // 'morning' or 'night'
  double moodBaseline = 0.5;

  // Avatar config
  int hairStyle = 0;
  int skinTone = 0;
  int outfitColor = 0;

  bool get hasCompletedOnboarding => name != null && name!.isNotEmpty;

  String get displayName => name ?? 'friend';
}
