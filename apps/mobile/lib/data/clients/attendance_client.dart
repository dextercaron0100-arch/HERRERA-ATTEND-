import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:geoattend_employee/core/database/app_database.dart';

class ClockResult {
  const ClockResult(this.decision, this.reasonCodes,
      {this.queued = false, this.distanceMeters, this.accuracyMeters});
  final String decision;
  final List<String> reasonCodes;
  final bool queued;
  final double? distanceMeters;
  final double? accuracyMeters;
}

class AttendanceClient {
  AttendanceClient(
      {required Dio dio,
      required AppDatabase database,
      required FlutterSecureStorage storage})
      : _dio = dio,
        _database = database,
        _storage = storage;
  final Dio _dio;
  final AppDatabase _database;
  final FlutterSecureStorage _storage;

  Future<ClockResult> submit(String kind) async {
    final employeeId = await _storage.read(key: 'employee_id');
    final worksiteId = await _storage.read(key: 'worksite_id');
    final registered = await _storage.read(key: 'device_registered') == 'true';
    if (employeeId == null || worksiteId == null || !registered) {
      return const ClockResult(
          'CONFIGURATION_REQUIRED', ['DEVICE_REGISTRATION_REQUIRED']);
    }
    if (!await _locationPermission()) {
      return const ClockResult('REJECTED', ['LOCATION_PERMISSION_DENIED']);
    }
    final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high));
    final payload = <String, dynamic>{
      'employeeId': employeeId,
      'worksiteId': worksiteId,
      'kind': kind,
      'capturedAt': DateTime.now().toUtc().toIso8601String(),
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracyMeters': position.accuracy.clamp(0.1, 10000),
      'idempotencyKey': const Uuid().v4(),
      'deviceId': await _storage.read(key: 'device_id') ?? 'flutter-android',
    };
    try {
      final result =
          await _send(payload, accuracyMeters: position.accuracy.toDouble());
      await syncPending();
      return result;
    } on DioException {
      await _database.enqueue(
          payload['idempotencyKey'] as String, jsonEncode(payload));
      return const ClockResult('QUEUED', ['OFFLINE_RETRY_PENDING'],
          queued: true);
    }
  }

  Future<int> syncPending() async {
    final pending = await _database.pending();
    var synced = 0;
    for (final item in pending) {
      try {
        await _send(jsonDecode(item.payload) as Map<String, dynamic>);
        await _database.removePending(item.idempotencyKey);
        synced++;
      } catch (error) {
        await _database.markAttempt(item.idempotencyKey, error.toString());
      }
    }
    return synced;
  }

  Future<ClockResult> _send(Map<String, dynamic> payload,
      {double? accuracyMeters}) async {
    final response = await _dio.post<Map<String, dynamic>>('/attendance/events',
        data: payload);
    final body = response.data;
    if (body == null) {
      throw StateError('Clock submission returned no data');
    }
    return ClockResult(body['decision'] as String,
        List<String>.from(body['reasonCodes'] as List),
        distanceMeters: (body['distanceMeters'] as num?)?.toDouble(),
        accuracyMeters: accuracyMeters);
  }

  Future<bool> _locationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }
}
