import 'package:dio/dio.dart';
import '../../domain/models/mood_entry.dart';

class MoodRepository {
  final Dio _dio;
  MoodRepository(this._dio);

  Future<MoodEntry> createMood(Map<String, dynamic> data) async {
    final response = await _dio.post('/mood', data: data);
    return MoodEntry.fromJson(response.data);
  }

  Future<List<MoodEntry>> getMoodHistory() async {
    final response = await _dio.get('/mood/history');
    final list = response.data as List;
    return list.map((e) => MoodEntry.fromJson(e)).toList();
  }

  Future<void> syncUnsynced(List<MoodEntry> entries) async {
    await _dio.post('/mood/sync', data: {
      'entries': entries.map((e) => e.toJson()).toList(),
    });
  }
}
