import 'package:dio/dio.dart';
import '../../domain/models/recovery_score.dart';

class RecoveryRepository {
  final Dio _dio;
  RecoveryRepository(this._dio);

  Future<RecoveryScore> submitHealthData(Map<String, dynamic> data) async {
    final response = await _dio.post('/recovery/health-data', data: data);
    return RecoveryScore.fromJson(response.data);
  }

  Future<RecoveryScore?> getLatestScore() async {
    final response = await _dio.get('/recovery/latest');
    if (response.data == null) return null;
    return RecoveryScore.fromJson(response.data);
  }

  Future<List<RecoveryScore>> getScoreHistory(int days) async {
    final response =
        await _dio.get('/recovery/history', queryParameters: {'days': days});
    final list = response.data as List;
    return list.map((e) => RecoveryScore.fromJson(e)).toList();
  }
}
