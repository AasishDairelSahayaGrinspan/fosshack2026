import 'package:flutter/foundation.dart';

enum AppTabTarget { home, journal, community, music, profile }

class AppNavigationService {
  AppNavigationService._();
  static final AppNavigationService _instance = AppNavigationService._();
  factory AppNavigationService() => _instance;

  final ValueNotifier<AppTabTarget?> tabRequest = ValueNotifier<AppTabTarget?>(
    null,
  );
  final ValueNotifier<AppTabTarget?> tabHighlight =
      ValueNotifier<AppTabTarget?>(null);
  final ValueNotifier<String?> musicRecommendation = ValueNotifier<String?>(
    null,
  );

  void requestTab(AppTabTarget target) {
    tabRequest.value = target;
  }

  void clearTabRequest() {
    tabRequest.value = null;
  }

  void highlightTab(AppTabTarget target) {
    tabHighlight.value = target;
  }

  void clearHighlight() {
    tabHighlight.value = null;
  }

  void setMusicRecommendation(String message) {
    musicRecommendation.value = message;
  }

  void clearMusicRecommendation() {
    musicRecommendation.value = null;
  }
}

