import 'package:flutter/foundation.dart';

/// OAuth configuration for all platforms.
/// Web uses HTTP(S) redirect URLs, mobile uses custom URI schemes.
class OAuthConfig {
  OAuthConfig._();

  // ─── Development Configuration ───
  static const String _devDomain = 'http://localhost:5000';

  // ─── Production Configuration ───
  // Replace with your actual production domain when deploying
  static const String _prodDomain = 'https://unravel.app'; // TODO: Update with actual domain

  // ─── Mobile Configuration ───
  static const String mobileCallbackScheme = 'appwrite-callback-unravel-app';

  // ─── Base URL Selection ───
  static String get baseUrl => kDebugMode ? _devDomain : _prodDomain;

  // ─── OAuth Redirect URLs (Web) ───
  /// Success redirect URL after OAuth authentication
  /// For web, redirect to root - Flutter will handle the authenticated session
  static String get successUrl => baseUrl;

  /// Failure redirect URL if OAuth authentication fails
  /// For web, redirect to root - user can retry login
  static String get failureUrl => baseUrl;

  /// OAuth callback page (alternative redirect destination)
  static String get callbackUrl => '$baseUrl/auth/callback';

  // ─── Configuration Getters ───
  /// Check if running in web platform
  static bool get isWeb => kIsWeb;

  /// Get the redirect URI based on platform
  static String getRedirectUri() {
    if (kIsWeb) {
      return baseUrl;
    } else {
      // Mobile platforms use custom URI scheme
      return '$mobileCallbackScheme://';
    }
  }
}
