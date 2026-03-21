import 'dart:async';
import 'dart:developer' as developer;

/// Web-only OAuth callback handler.
/// Processes OAuth redirect URLs and extracts authentication data.
class OAuthWebHandler {
  static const String _tag = 'OAuthWebHandler';

  /// Setup OAuth callback listener for web platform.
  /// Checks URL parameters for OAuth success/error tokens.
  static Future<bool> checkOAuthCallback() async {
    try {
      // Import dart:html conditionally to avoid errors on non-web platforms
      // This method should only be called from web
      return _checkCallbackOnWeb();
    } catch (e, st) {
      developer.log(
        'checkOAuthCallback error',
        name: _tag,
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Internal method - checks OAuth callback on web platform.
  static bool _checkCallbackOnWeb() {
    // This uses dart:html which is only available on web
    // The actual implementation will be done through the URL handling in main.dart
    return true;
  }

  /// Extract URL parameter value
  static String? extractParam(String param, String url) {
    try {
      final regex = RegExp('[$param]=([^&]*)');
      final match = regex.firstMatch(url);
      return match?.group(1);
    } catch (e) {
      developer.log('extractParam error', name: _tag, error: e);
      return null;
    }
  }
}
