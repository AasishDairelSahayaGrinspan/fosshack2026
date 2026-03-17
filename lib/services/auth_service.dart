import 'dart:developer' as developer;
import 'dart:math';

import 'package:appwrite/enums.dart' as enums;
import 'package:flutter/foundation.dart';

import 'local_data_service.dart';
import 'notification_service.dart';

class LocalUser {
  final String $id;
  String name;
  final String? phone;
  final bool isGuest;

  LocalUser({
    required this.$id,
    required this.name,
    this.phone,
    this.isGuest = false,
  });

  factory LocalUser.fromJson(Map<String, dynamic> json) {
    return LocalUser(
      $id: json['id'] as String,
      name: (json['name'] as String?) ?? 'friend',
      phone: json['phone'] as String?,
      isGuest: (json['isGuest'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': $id,
        'name': name,
        'phone': phone,
        'isGuest': isGuest,
      };
}

class OtpToken {
  final String userId;
  OtpToken(this.userId);
}

/// OTP expiry duration — codes are invalid after this period.
const Duration _otpExpiry = Duration(minutes: 5);

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _tag = 'AuthService';

  LocalUser? _currentUser;
  LocalUser? get currentUser => _currentUser;

  String? _pendingOtpUserId;
  String? _pendingOtpCode;
  String? _pendingPhone;
  DateTime? _pendingOtpCreatedAt;

  Future<bool> isLoggedIn() async {
    try {
      await LocalDataService().init();
      final userId = LocalDataService().getSessionUserId();
      if (userId == null) {
        _currentUser = null;
        return false;
      }
      final userJson = LocalDataService().getUser(userId);
      if (userJson == null) {
        _currentUser = null;
        await LocalDataService().setSessionUserId(null);
        return false;
      }
      _currentUser = LocalUser.fromJson(userJson);
      return true;
    } catch (e, st) {
      developer.log('isLoggedIn failed', name: _tag, error: e, stackTrace: st);
      _currentUser = null;
      return false;
    }
  }

  /// Generates a cryptographically random 6-digit OTP.
  String _generateOtp() {
    final random = Random.secure();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  Future<OtpToken> sendOtp(String phone) async {
    try {
      await LocalDataService().init();
      final userId = 'phone_${phone.replaceAll(RegExp(r'\D'), '')}';
      _pendingOtpUserId = userId;
      _pendingOtpCode = _generateOtp();
      _pendingPhone = phone;
      _pendingOtpCreatedAt = DateTime.now();

      // In debug builds, log the OTP for testing purposes.
      if (kDebugMode) {
        developer.log('OTP for $phone: $_pendingOtpCode', name: _tag);
      }

      // Send OTP as a local notification so the user can see the code.
      try {
        await NotificationService().showOtpNotification(_pendingOtpCode!);
      } catch (e) {
        developer.log('OTP notification failed', name: _tag, error: e);
      }

      await LocalDataService().addAnalytics(
        'otp_sent',
        payload: <String, dynamic>{'phone': phone},
      );
      return OtpToken(userId);
    } catch (e, st) {
      developer.log('sendOtp failed', name: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> verifyOtp({
    required String userId,
    required String otp,
  }) async {
    try {
      await LocalDataService().init();

      // Check if OTP has expired.
      if (_pendingOtpCreatedAt != null &&
          DateTime.now().difference(_pendingOtpCreatedAt!) > _otpExpiry) {
        _pendingOtpCode = null;
        _pendingOtpCreatedAt = null;
        throw Exception('OTP has expired. Please request a new one.');
      }

      if (_pendingOtpUserId != userId || _pendingOtpCode != otp) {
        throw Exception('Invalid OTP');
      }

      // OTP verified — clear pending state.
      _pendingOtpCode = null;
      _pendingOtpCreatedAt = null;

      final existing = LocalDataService().getUser(userId);
      final user = LocalUser(
        $id: userId,
        name: existing?['name'] as String? ?? 'friend',
        phone: _pendingPhone,
        isGuest: false,
      );
      _currentUser = user;
      await LocalDataService().saveUser(userId, user.toJson());
      await LocalDataService().setSessionUserId(userId);
      await LocalDataService().addAnalytics(
        'otp_verified',
        payload: <String, dynamic>{'userId': userId},
      );
    } on Exception {
      rethrow;
    } catch (e, st) {
      developer.log('verifyOtp failed', name: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> oAuthLogin(enums.OAuthProvider provider) async {
    try {
      await LocalDataService().init();
      final random = Random.secure().nextInt(999999).toString().padLeft(6, '0');
      final userId = '${provider.name}_$random';
      final existing = LocalDataService().getUser(userId);
      final user = LocalUser(
        $id: userId,
        name: existing?['name'] as String? ?? provider.name,
        isGuest: false,
      );
      _currentUser = user;
      await LocalDataService().saveUser(userId, user.toJson());
      await LocalDataService().setSessionUserId(userId);
      await LocalDataService().addAnalytics(
        'oauth_login',
        payload: <String, dynamic>{
          'provider': provider.name,
          'userId': userId,
        },
      );
    } catch (e, st) {
      developer.log('oAuthLogin failed', name: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> guestLogin() async {
    try {
      await LocalDataService().init();
      final userId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      final user = LocalUser($id: userId, name: 'Guest', isGuest: true);
      _currentUser = user;
      await LocalDataService().saveUser(userId, user.toJson());
      await LocalDataService().setSessionUserId(userId);
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
      await LocalDataService().setSessionUserId(null);
      _currentUser = null;
      await LocalDataService().addAnalytics('logout');
    } catch (e, st) {
      developer.log('logout failed', name: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }
}

