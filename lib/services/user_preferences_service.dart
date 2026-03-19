import 'dart:developer' as developer;

import 'package:appwrite/appwrite.dart';

import 'appwrite_constants.dart';
import 'appwrite_service.dart';
import 'auth_service.dart';
import 'avatar_service.dart';
import 'local_data_service.dart';

/// User preferences - synced to Appwrite users collection, cached locally.
class UserPreferencesService {
  static final UserPreferencesService _instance = UserPreferencesService._();
  factory UserPreferencesService() => _instance;
  UserPreferencesService._();

  static const String _tag = 'UserPreferencesService';

  String? name;
  String? about;
  String? ageGroup;
  String? gender;
  String? relationshipStatus;
  List<String> concerns = <String>[];
  String? sleepSchedule;
  double moodBaseline = 0.5;
  String communityPreference = 'yes';
  List<String> musicLanguages = <String>[];
  Map<String, dynamic>? avatarConfigMap;
  
  // New fields for backend integration
  String? employmentStatus; // 'student', 'employee', 'retired'
  String? shiftPreference; // 'day', 'night'
  int? age; // actual age value
  String? heightCm; // height in cm
  String? weightKg; // weight in kg
  double? bmi; // calculated BMI
  String? bmiStatus; // 'underweight', 'normal', 'overweight', 'obese'

  late String avatarSeed = AvatarService().generateRandomSeed();
  late String avatarStyle = AvatarService().getRandomStyle();

  /// Avatar config JSON for the custom avatar system (Phase 2).
  String? avatarData;

  bool get hasMusicSetup => musicLanguages.isNotEmpty;
  bool get hasCompletedOnboarding => name != null && name!.isNotEmpty;
  String get displayName => name ?? 'friend';
  String get displayAbout => (about != null && about!.isNotEmpty)
      ? about!
      : "Hey there! I'm using Unravel.";

  String getAvatarUrl() {
    return AvatarService().getAvatarUrl(seed: avatarSeed, style: avatarStyle);
  }

  void regenerateAvatar() {
    avatarSeed = AvatarService().generateRandomSeed();
  }

  void setAvatarStyle(String style) {
    avatarStyle = style;
  }

  /// Load preferences from Appwrite, fallback to local cache.
  Future<void> loadFromRemote() async {
    final user = AuthService().currentUser;
    if (user == null) {
      await loadFromLocal();
      return;
    }

    try {
      final db = AppwriteService().databases;
      final doc = await db.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: user.$id,
      );
      final data = doc.data;
      _applyData(data);
      // Cache locally
      await LocalDataService().init();
      await LocalDataService().saveUserPrefs(user.$id, _toMap());
    } on AppwriteException catch (e) {
      developer.log('loadFromRemote failed: ${e.message}', name: _tag);
      await loadFromLocal();
    } catch (e) {
      developer.log('loadFromRemote failed', name: _tag, error: e);
      await loadFromLocal();
    }
  }

  /// Save preferences to Appwrite, then cache locally.
  Future<void> saveToRemote() async {
    final user = AuthService().currentUser;
    if (user == null) {
      await saveToLocal();
      return;
    }

    final data = _toMap();

    try {
      final db = AppwriteService().databases;
      try {
        await db.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollection,
          documentId: user.$id,
          data: data,
        );
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          // Document doesn't exist yet, create it
          await db.createDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.usersCollection,
            documentId: user.$id,
            data: data,
            permissions: [
              Permission.read(Role.user(user.$id)),
              Permission.write(Role.user(user.$id)),
            ],
          );
        } else {
          rethrow;
        }
      }
    } on AppwriteException catch (e) {
      developer.log('saveToRemote failed: ${e.message}', name: _tag);
    } catch (e) {
      developer.log('saveToRemote failed', name: _tag, error: e);
    }

    // Always cache locally
    await saveToLocal();
  }

  Future<void> loadFromLocal() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    await LocalDataService().init();
    final data = LocalDataService().getUserPrefs(user.$id);
    _applyData(data);
  }

  Future<void> saveToLocal() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    await LocalDataService().init();
    await LocalDataService().saveUserPrefs(user.$id, _toMap());
    await LocalDataService().addAnalytics(
      'user_prefs_saved',
      payload: <String, dynamic>{'userId': user.$id},
    );
  }

  void _applyData(Map<String, dynamic> data) {
    name = data['name'] as String?;
    about = data['about'] as String?;
    ageGroup = data['ageGroup'] as String?;
    gender = data['gender'] as String?;
    relationshipStatus = data['relationshipStatus'] as String?;
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
    avatarData = data['avatarData'] as String?;
    final rawAvatar = data['avatarConfig'];
    if (rawAvatar is Map<String, dynamic>) {
      avatarConfigMap = Map<String, dynamic>.from(rawAvatar);
    }
    // New fields
    employmentStatus = data['employmentStatus'] as String?;
    shiftPreference = data['shiftPreference'] as String?;
    age = (data['age'] as num?)?.toInt();
    heightCm = data['heightCm'] as String?;
    weightKg = data['weightKg'] as String?;
    bmi = (data['bmi'] as num?)?.toDouble();
    bmiStatus = data['bmiStatus'] as String?;
  }

  Map<String, dynamic> _toMap() => <String, dynamic>{
    'name': name,
    'about': about,
    'ageGroup': ageGroup,
    'gender': gender,
    'relationshipStatus': relationshipStatus,
    'concerns': concerns,
    'sleepSchedule': sleepSchedule,
    'moodBaseline': moodBaseline,
    'communityPreference': communityPreference,
    'musicLanguages': musicLanguages,
    'avatarSeed': avatarSeed,
    'avatarStyle': avatarStyle,
    'avatarData': avatarData,
    'avatarUrl': getAvatarUrl(),
    'avatarConfig': avatarConfigMap,
    // New fields
    'employmentStatus': employmentStatus,
    'shiftPreference': shiftPreference,
    'age': age,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'bmi': bmi,
    'bmiStatus': bmiStatus,
  };
}
