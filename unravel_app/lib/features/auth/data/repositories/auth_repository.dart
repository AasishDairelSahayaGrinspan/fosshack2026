import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

class AuthRepository {
  final Account _account;
  AuthRepository(this._account);

  Future<models.Session> login(String email, String password) async {
    return await _account.createEmailPasswordSession(
      email: email,
      password: password,
    );
  }

  Future<models.User> register(
      String email, String password, String displayName) async {
    await _account.create(
      userId: ID.unique(),
      email: email,
      password: password,
      name: displayName,
    );
    await _account.createEmailPasswordSession(
      email: email,
      password: password,
    );
    return await _account.get();
  }

  Future<models.User> getCurrentUser() async {
    return await _account.get();
  }

  Future<void> logout() async {
    await _account.deleteSession(sessionId: 'current');
  }
}
