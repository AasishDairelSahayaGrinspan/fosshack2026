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

  // ─── Phone OTP ───

  /// Send OTP to phone number. Returns the token for verification.
  /// [phone] must include country code, e.g. '+919876543210'.
  Future<models.Token> sendOtp(String phone) async {
    return await _account.createPhoneToken(
      userId: ID.unique(),
      phone: phone,
    );
  }

  /// Verify the OTP code. Returns a session on success.
  Future<models.Session> verifyOtp({
    required String userId,
    required String otp,
  }) async {
    final session = await _account.updatePhoneSession(
      userId: userId,
      secret: otp,
    );
    _currentUser = await _account.get();
    return session;
  }

  // ─── OAuth (Google / Apple) ───

  /// Launch OAuth flow for the given provider.
  /// [provider] should be 'google' or 'apple'.
  Future<void> oAuthLogin(enums.OAuthProvider provider) async {
    await _account.createOAuth2Session(provider: provider);
    _currentUser = await _account.get();
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
