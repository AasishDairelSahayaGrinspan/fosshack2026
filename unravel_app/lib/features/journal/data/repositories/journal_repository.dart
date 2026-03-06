import 'package:dio/dio.dart';
import '../../domain/models/journal_entry.dart';

class JournalRepository {
  final Dio _dio;
  JournalRepository(this._dio);

  Future<JournalEntry> createEntry(Map<String, dynamic> data) async {
    final response = await _dio.post('/journal', data: data);
    return JournalEntry.fromJson(response.data);
  }

  Future<List<JournalEntry>> getEntries() async {
    final response = await _dio.get('/journal');
    final list = response.data as List;
    return list.map((e) => JournalEntry.fromJson(e)).toList();
  }

  Future<void> syncUnsynced(List<JournalEntry> entries) async {
    await _dio.post('/journal/sync', data: {
      'entries': entries.map((e) => e.toJson()).toList(),
    });
  }
}
