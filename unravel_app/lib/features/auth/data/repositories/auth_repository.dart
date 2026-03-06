import 'package:dio/dio.dart';

class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> register(
      String email, String password, String displayName) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'displayName': displayName,
    });
    return response.data;
  }
}
