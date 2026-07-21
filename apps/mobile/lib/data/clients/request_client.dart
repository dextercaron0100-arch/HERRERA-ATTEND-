import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RequestClient {
  RequestClient({required Dio dio, required FlutterSecureStorage storage})
      : _dio = dio,
        _storage = storage;
  final Dio _dio;
  final FlutterSecureStorage _storage;

  Future<String> submit(
      {required String type,
      required DateTime startsAt,
      required DateTime endsAt,
      required String reason,
      Map<String, dynamic> evidence = const {}}) async {
    final employeeId = await _storage.read(key: 'employee_id');
    if (employeeId == null) throw StateError('Employee session is missing');
    final response = await _dio.post<Map<String, dynamic>>('/requests', data: {
      'employeeId': employeeId,
      'type': type,
      'startsAt': startsAt.toUtc().toIso8601String(),
      'endsAt': endsAt.toUtc().toIso8601String(),
      'reason': reason,
      'evidence': evidence,
    });
    final id = response.data?['id'];
    if (id is! String) throw StateError('Request returned no identifier');
    return id;
  }
}
