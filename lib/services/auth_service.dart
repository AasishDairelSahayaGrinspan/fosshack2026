import 'dart:developer' as developer;

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as enums;
import 'package:appwrite/models.dart' as models;

import 'appwrite_service.dart';
import 'local_data_service.dart';

class LocalUser {
  final String $id;
  String name;
  final String? email;
  final bool isGuest;

  LocalUser({
    required this.$id,
    required this.name,
    this.email,
    this.isGuest = false,
  });

  factory LocalUser.fromJson(Map<String, dynamic> json) {
    return LocalUser(
      $id: json['id'] as String,
      name: (json['name'] as String?) ?? 'friend',
      email: json['email'] as String?,
      isGuest: (json['isGuest'] as bool?) ?? false,
    );
  }

  factory LocalUser.fromAppwriteUser(models.User user) {
    return LocalUser(
      $id: user.$id,
      name: user.name.isNotEmpty ? user.name : 'friend',
      email: user.email.isNotEmpty ? user.email : null,
      isGuest: user.email.isEmpty,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': $id,
    'name': name,
    'email': email,
    'isGuest': isGuest,
  };
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _tag = 'AuthService';

  final Account _account = AppwriteService().account;

  LocalUser? _currentUser;
  LocalUser? get currentUser => _currentUser;

  /// Check if user has an active Appwrite session.
  Future<bool> isLoggedIn() async {
    try {
      await LocalDataService().init();
      final user = await _account.get();
      _currentUser = LocalUser.fromAppwriteUser(user);
      // Cache locally
      await LocalDataService().saveUser(
        _currentUser!.$id,
        _currentUser!.toJson(),
      );
      await LocalDataService().setSessionUserId(_currentUser!.$id);
      return true;
    } on AppwriteException catch (e) {
      developer.log('isLoggedIn: no session ($e)', name: _tag);
      // Fall back to local cache
      final userId = LocalDataService().getSessionUserId();
      if (userId != null) {
        final userJson = LocalDataService().getUser(userId);
        if (userJson != null) {
          _currentUser = LocalUser.fromJson(userJson);
          return true;
        }
      }
      _currentUser = null;
      return false;
    } catch (e, st) {
      developer.log('isLoggedIn failed', name: _tag, error: e, stackTrace: st);
      _currentUser = null;
      return false;
    }
  }

  /// Sign up with email and password. Creates account + session.
  Future<void> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      await LocalDataService().init();
      await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      // Create session after signup
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      final user = await _account.get();
      _currentUser = LocalUser.fromAppwriteUser(user);
      await LocalDataService().saveUser(
        _currentUser!.$id,
        _currentUser!.toJson(),
      );
      await LocalDataService().setSessionUserId(_currentUser!.$id);
      await LocalDataService().addAnalytics(
        'signup',
        payload: <String, dynamic>{'userId': _currentUser!.$id},
      );
    } on AppwriteException catch (e) {
      developer.log('signup failed: ${e.message}', name: _tag);
      if (e.code == 409) {
        throw Exception('An account with this email already exists.');
      } else if (e.message?.contains('password') ?? false) {
        throw Exception('Password must be at least 8 characters.');
      }
      throw Exception(e.message ?? 'Signup failed. Please try again.');
    } catch (e, st) {
      developer.log('signup failed', name: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Log in with email and password.
  Future<void> login({required String email, required String password}) async {
    try {
      await LocalDataService().init();
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      final user = await _account.get();
      _currentUser = LocalUser.fromAppwriteUser(user);
      await LocalDataService().saveUser(
        _currentUser!.$id,
        _currentUser!.toJson(),
      );
      await LocalDataService().setSessionUserId(_currentUser!.$id);
      await LocalDataService().addAnalytics(
        'login',
        payload: <String, dynamic>{'userId': _currentUser!.$id},
      );
    } on AppwriteException catch (e) {
      developer.log('login failed: ${e.message}', name: _tag);
      if (e.code == 401) {
        throw Exception('Invalid email or password.');
      }
      throw Exception(e.message ?? 'Login failed. Please try again.');
    } catch (e, st) {
      developer.log('login failed', name: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  /// OAuth login (Google, Apple) — opens browser for real OAuth flow.
  /// On web: OAuth session is created and browser handles redirect
  /// On mobile: Uses custom URI schemes configured in native code
  Future<void> oAuthLogin(enums.OAuthProvider provider) async {
    try {
      await LocalDataService().init();

      // Appwrite SDK v22+ handles OAuth differently on web
      // Simply call createOAuth2Session - Appwrite handles the redirect
      // Make sure redirect URI is configured in Appwrite console
      await _account.createOAuth2Session(provider: provider);

      final user = await _account.get();
      _currentUser = LocalUser.fromAppwriteUser(user);
      await LocalDataService().saveUser(
        _currentUser!.$id,
        _currentUser!.toJson(),
      );
      await LocalDataService().setSessionUserId(_currentUser!.$id);
      await LocalDataService().addAnalytics(
        'oauth_login',
        payload: <String, dynamic>{
          'provider': provider.name,
          'userId': _currentUser!.$id,
        },
      );
    } catch (e, st) {
      developer.log('oAuthLogin failed', name: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Guest login — creates an anonymous Appwrite session.
  Future<void> guestLogin() async {
    try {
      await LocalDataService().init();
      await _account.createAnonymousSession();
      final user = await _account.get();
      _currentUser = LocalUser($id: user.$id, name: 'Guest', isGuest: true);
      await LocalDataService().saveUser(
        _currentUser!.$id,
        _currentUser!.toJson(),
      );
      await LocalDataService().setSessionUserId(_currentUser!.$id);
      await LocalDataService().addAnalytics('guest_login');
    } catch (e, st) {
      developer.log('guestLogin failed', name: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<LocalUser> getUser() async {
    if (_currentUser != null) return _currentUser!;
    final loggedIn = await isLoggedIn();
    if (!loggedIn || _currentUser == null) {
      throw Exception('No active session');
    }
    return _currentUser!;
  }

  Future<void> updateName(String name) async {
    try {
      final user = _currentUser;
      if (user == null) return;
      try {
        await _account.updateName(name: name);
      } on AppwriteException catch (e) {
        developer.log('updateName remote failed: ${e.message}', name: _tag);
      }
      user.name = name;
      await LocalDataService().saveUser(user.$id, user.toJson());
      await LocalDataService().addAnalytics(
        'user_name_updated',
        payload: <String, dynamic>{'userId': user.$id},
      );
    } catch (e, st) {
      developer.log('updateName failed', name: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      try {
        await _account.deleteSession(sessionId: 'current');
      } on AppwriteException catch (e) {
        developer.log('logout remote failed: ${e.message}', name: _tag);
      }
      await LocalDataService().setSessionUserId(null);
      _currentUser = null;
      await LocalDataService().addAnalytics('logout');
    } catch (e, st) {
      developer.log('logout failed', name: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }
}
