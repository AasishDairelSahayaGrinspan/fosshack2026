import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/auth_repository.dart';
import '../models/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(appwriteAccountProvider));
});

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    try {
      final account = ref.read(appwriteAccountProvider);
      final user = await account.get();
      return User(
        id: user.$id,
        email: user.email,
        displayName: user.name,
        createdAt: DateTime.parse(user.$createdAt),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.login(email, password);
      final user = await repo.getCurrentUser();
      state = AsyncData(User(
        id: user.$id,
        email: user.email,
        displayName: user.name,
        createdAt: DateTime.parse(user.$createdAt),
      ));
    } on AppwriteException catch (e) {
      state = AsyncError(e.message ?? 'Login failed', StackTrace.current);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> register(String email, String password, String displayName) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.register(email, password, displayName);
      state = AsyncData(User(
        id: user.$id,
        email: user.email,
        displayName: user.name,
        createdAt: DateTime.parse(user.$createdAt),
      ));
    } on AppwriteException catch (e) {
      state = AsyncError(e.message ?? 'Registration failed', StackTrace.current);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> logout() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.logout();
    } catch (_) {}
    state = const AsyncData(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(() => AuthNotifier());
