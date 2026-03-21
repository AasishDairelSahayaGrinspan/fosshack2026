import 'dart:convert';
import 'dart:developer' as developer;

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as enums;

import 'appwrite_constants.dart';
import 'appwrite_service.dart';

class WellnessCloudService {
  WellnessCloudService._();
  static final WellnessCloudService _instance = WellnessCloudService._();
  factory WellnessCloudService() => _instance;

  static const String _tag = 'WellnessCloudService';

  final Functions _functions = AppwriteService().functions;

  Future<Map<String, dynamic>> logDailyMetrics({
    required String userId,
    required int mood,
    required double sleep,
    required int stress,
    required int energy,
    required int anxiety,
    bool? exercise,
    String? journaling,
  }) async {
    final payload = <String, dynamic>{
      'action': 'log',
      'userId': userId,
      'mood': mood,
      'sleep': sleep,
      'stress': stress,
      'energy': energy,
      'anxiety': anxiety,
      'exercise': exercise,
      'journaling': journaling,
    };

    return _execute(path: '/log', body: payload);
  }

  Future<Map<String, dynamic>> getTrend({
    required String userId,
  }) {
    return _execute(
      path: '/trend',
      body: <String, dynamic>{'action': 'trend', 'userId': userId},
    );
  }

  Future<Map<String, dynamic>> getInsights({
    required String userId,
  }) {
    return _execute(
      path: '/insights',
      body: <String, dynamic>{'action': 'insights', 'userId': userId},
    );
  }

  Future<Map<String, dynamic>> _execute({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    try {
      final execution = await _functions.createExecution(
        functionId: AppwriteConstants.wellnessFunctionId,
        body: jsonEncode(body),
        path: path,
        method: enums.ExecutionMethod.pOST,
        headers: const <String, dynamic>{'content-type': 'application/json'},
      );

      final raw = execution.responseBody;
      if (raw.isEmpty) {
        return <String, dynamic>{'success': false, 'error': 'Empty response'};
      }

      final parsed = jsonDecode(raw);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }

      return <String, dynamic>{
        'success': false,
        'error': 'Unexpected response format',
      };
    } on AppwriteException catch (e, st) {
      developer.log(
        'Function call failed: ${e.message}',
        name: _tag,
        error: e,
        stackTrace: st,
      );
      return <String, dynamic>{
        'success': false,
        'error': e.message ?? 'Appwrite function execution failed',
      };
    } catch (e, st) {
      developer.log(
        'Function call failed',
        name: _tag,
        error: e,
        stackTrace: st,
      );
      return <String, dynamic>{
        'success': false,
        'error': 'Unexpected wellness cloud failure',
      };
    }
  }
}
