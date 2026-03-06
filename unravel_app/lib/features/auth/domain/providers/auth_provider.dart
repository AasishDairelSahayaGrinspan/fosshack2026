import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../models/user.dart';

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.read(key: 'jwt');
    if (token == null) return null;
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/auth/me');
      return User.fromJson(response.data);
    } catch (_) {
      await storage.delete(key: 'jwt');
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/auth/login', data: {'email': email, 'password': password});
      final token = response.data['accessToken'] as String;
      await ref.read(secureStorageProvider).write(key: 'jwt', value: token);
      final userResponse = await dio.get('/auth/me');
      state = AsyncData(User.fromJson(userResponse.data));
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> register(String email, String password, String displayName) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/auth/register', data: {
        'email': email, 'password': password, 'displayName': displayName,
      });
      final token = response.data['accessToken'] as String;
      await ref.read(secureStorageProvider).write(key: 'jwt', value: token);
      final userResponse = await dio.get('/auth/me');
      state = AsyncData(User.fromJson(userResponse.data));
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> logout() async {
    await ref.read(secureStorageProvider).delete(key: 'jwt');
    state = const AsyncData(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(() => AuthNotifier());
