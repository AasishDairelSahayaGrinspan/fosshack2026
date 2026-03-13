import 'dart:developer' as developer;
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as enums;
import 'package:appwrite/models.dart' as models;
import 'appwrite_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final Account _account = AppwriteService().account;

  // ─── Current user cache ───
  models.User? _currentUser;
  models.User? get currentUser => _currentUser;

  /// Check if user has an active session.
  Future<bool> isLoggedIn() async {
    try {
      _currentUser = await _account.get();
      return true;
    } catch (_) {
      _currentUser = null;
      return false;
    }
  }

  // ─── Email / Password Auth ───

  /// Create a new account and log in.
  Future<models.User> emailSignUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _currentUser = await _account.create(
      userId: ID.unique(),
      email: email,
      password: password,
      name: name,
    );
    // Auto-login after sign-up
    await _account.createEmailPasswordSession(
      email: email,
      password: password,
    );
    _currentUser = await _account.get();
    return _currentUser!;
  }

  /// Log in with existing email/password.
  Future<models.Session> emailLogin({
    required String email,
    required String password,
  }) async {
    final session = await _account.createEmailPasswordSession(
      email: email,
      password: password,
    );
    _currentUser = await _account.get();
    return session;
  }

  /// Send a password-recovery email.
  Future<models.Token> forgotPassword(String email) async {
    return await _account.createRecovery(
      email: email,
      url: 'https://unravel-app.com/reset-password',
    );
  }

  // ─── OAuth (Google / Apple) ───

  /// Launch OAuth flow for the given provider.
  /// [provider] should be 'google' or 'apple'.
  /// Throws [AppwriteException] if OAuth session creation fails.
  Future<void> oAuthLogin(enums.OAuthProvider provider) async {
    try {
      developer.log('Starting OAuth login with provider: $provider');
      await _account.createOAuth2Session(
        provider: provider,
      );
      _currentUser = await _account.get();
      developer.log('OAuth login successful for user: ${_currentUser?.$id}');
    } on AppwriteException catch (e) {
      developer.log(
        'OAuth login failed: ${e.message}',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    } catch (e) {
      developer.log(
        'Unexpected error during OAuth login',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  // ─── Session Management ───

  Future<models.User> getUser() async {
    _currentUser = await _account.get();
    return _currentUser!;
  }

  Future<void> updateName(String name) async {
    _currentUser = await _account.updateName(name: name);
  }

  Future<void> logout() async {
    await _account.deleteSession(sessionId: 'current');
    _currentUser = null;
  }
}
