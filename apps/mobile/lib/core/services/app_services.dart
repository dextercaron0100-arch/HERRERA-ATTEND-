import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geoattend_employee/core/database/app_database.dart';
import 'package:geoattend_employee/data/clients/attendance_client.dart';
import 'package:geoattend_employee/data/clients/mobile_client.dart';
import 'package:geoattend_employee/data/clients/request_client.dart';

const _configuredApiUrl = String.fromEnvironment('API_URL');
final apiUrl = _configuredApiUrl.isNotEmpty
    ? _configuredApiUrl
    : (kReleaseMode ? '' : 'http://10.0.2.2:4000/api');

final secureStorageProvider = Provider<FlutterSecureStorage>(
    (ref) => const FlutterSecureStorage(aOptions: AndroidOptions()));
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
final dioProvider = Provider<Dio>((ref) {
  if (apiUrl.isEmpty) {
    throw StateError(
        'A production API_URL must be supplied with --dart-define.');
  }
  if (kReleaseMode && !apiUrl.startsWith('https://')) {
    throw StateError('Production API_URL must use HTTPS.');
  }
  final dio = Dio(BaseOptions(
      baseUrl: apiUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
      sendTimeout: const Duration(seconds: 12),
      headers: {'accept': 'application/json'}));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && session.accessToken.isNotEmpty) {
      options.headers['authorization'] = 'Bearer ${session.accessToken}';
    }
    handler.next(options);
  }));
  return dio;
});
final attendanceClientProvider = Provider<AttendanceClient>((ref) =>
    AttendanceClient(
        dio: ref.watch(dioProvider),
        database: ref.watch(databaseProvider),
        storage: ref.watch(secureStorageProvider)));
final requestClientProvider = Provider<RequestClient>((ref) => RequestClient(
    dio: ref.watch(dioProvider), storage: ref.watch(secureStorageProvider)));
final mobileClientProvider =
    Provider<MobileClient>((ref) => MobileClient(ref.watch(dioProvider)));
final mobileOverviewProvider =
    FutureProvider.autoDispose<MobileOverview>((ref) {
  final employeeId = ref.watch(authControllerProvider).employeeId;
  if (employeeId == null) throw StateError('Employee session is missing');
  return ref.watch(mobileClientProvider).overview(employeeId);
});

class AuthSession {
  const AuthSession(
      {required this.initialized,
      required this.authenticated,
      this.employeeId,
      this.organizationId,
      this.worksiteId,
      this.employeeNumber,
      this.name});
  final bool initialized;
  final bool authenticated;
  final String? employeeId;
  final String? organizationId;
  final String? worksiteId;
  final String? employeeNumber;
  final String? name;
}

class AuthController extends Notifier<AuthSession> {
  @override
  AuthSession build() {
    Future.microtask(_restore);
    return const AuthSession(initialized: false, authenticated: false);
  }

  Future<void> _restore() async {
    final storage = ref.read(secureStorageProvider);
    final remembered = await storage.read(key: 'remember_session') == 'true';
    if (!remembered || Supabase.instance.client.auth.currentSession == null) {
      if (!remembered) await Supabase.instance.client.auth.signOut();
      state = const AuthSession(initialized: true, authenticated: false);
      return;
    }
    if (await _loadEmployee(remember: true, verifyLocation: true) != null) {
      await logout();
    }
  }

  Future<String?> login(
      {required String username,
      required String password,
      required bool remember}) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
          email: username.trim().toLowerCase(), password: password);
      if (response.session == null) return 'Incorrect work email or password.';
      final error =
          await _loadEmployee(remember: remember, verifyLocation: true);
      if (error != null) await Supabase.instance.client.auth.signOut();
      return error;
    } on AuthException {
      return 'Incorrect work email or password.';
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
          email.trim().toLowerCase(),
          redirectTo: 'com.herrera.attend://reset-password');
      return true;
    } on AuthException {
      return false;
    }
  }

  Future<bool> updatePassword(String password) async {
    try {
      await Supabase.instance.client.auth
          .updateUser(UserAttributes(password: password));
      return await _loadEmployee(remember: true, verifyLocation: true) == null;
    } on AuthException {
      return false;
    }
  }

  Future<String?> _loadEmployee(
      {required bool remember, required bool verifyLocation}) async {
    try {
      final dio = ref.read(dioProvider);
      final Response<Map<String, dynamic>> response;
      if (verifyLocation) {
        final position = await _currentLoginPosition();
        response = await dio
            .post<Map<String, dynamic>>('/workforce/mobile-session', data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracyMeters': position.accuracy.clamp(0.1, 10000).toDouble(),
        });
      } else {
        response = await dio.get<Map<String, dynamic>>('/workforce/session');
      }
      final employee = response.data?['employee'];
      if (employee is! Map<String, dynamic>) {
        return 'Your employee profile is not available. Contact HR.';
      }
      await _completeLogin(remember: remember, employee: employee);
      return null;
    } on StateError catch (error) {
      return error.message;
    } on DioException catch (error) {
      return _apiErrorMessage(error);
    }
  }

  Future<Position> _currentLoginPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError(
          'Turn on device location to sign in at your assigned worksite.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw StateError(
          'Location permission is blocked. Enable it in device settings to sign in.');
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw StateError(
          'Location permission is required to sign in at your assigned worksite.');
    }
    return Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high));
  }

  String _apiErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
      if (message is List && message.isNotEmpty) return message.join(' ');
    }
    return 'Unable to verify your worksite location. Check your connection and try again.';
  }

  Future<void> _completeLogin(
      {required bool remember, required Map<String, dynamic> employee}) async {
    final storage = ref.read(secureStorageProvider);
    if (remember) {
      await storage.write(key: 'remember_session', value: 'true');
    } else {
      await storage.delete(key: 'remember_session');
    }
    final worksite = employee['worksite'];
    await storage.delete(key: 'access_token');
    await storage.write(key: 'employee_id', value: employee['id'] as String);
    await storage.write(
        key: 'organization_id', value: employee['organizationId'] as String);
    await storage.write(
        key: 'employee_number', value: employee['employeeNumber'] as String);
    await storage.write(
        key: 'employee_name', value: employee['name'] as String);
    if (worksite is Map<String, dynamic>) {
      await storage.write(key: 'worksite_id', value: worksite['id'] as String);
    }
    state = AuthSession(
        initialized: true,
        authenticated: true,
        employeeId: employee['id'] as String,
        organizationId: employee['organizationId'] as String,
        worksiteId:
            worksite is Map<String, dynamic> ? worksite['id'] as String : null,
        employeeNumber: employee['employeeNumber'] as String,
        name: employee['name'] as String);
  }

  Future<String?> biometricLogin() async {
    if (Supabase.instance.client.auth.currentSession == null) {
      return 'Sign in with your password before using biometrics.';
    }
    final authenticated = await verifyStrongBiometric(
        reason: 'Verify your identity to open HERRERA ATTEND');
    if (authenticated) {
      return _loadEmployee(remember: true, verifyLocation: true);
    }
    return 'Face or fingerprint verification was cancelled or unavailable.';
  }

  Future<bool> verifyStrongBiometric({required String reason}) async {
    final localAuth = LocalAuthentication();
    if (!await localAuth.isDeviceSupported() ||
        !await localAuth.canCheckBiometrics) {
      return false;
    }
    final available = await localAuth.getAvailableBiometrics();
    final strongEnough = Platform.isAndroid
        ? available.contains(BiometricType.strong)
        : available.any((type) =>
            type == BiometricType.face ||
            type == BiometricType.fingerprint ||
            type == BiometricType.strong);
    if (!strongEnough) return false;
    return localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true);
  }

  Future<void> logout() async {
    final storage = ref.read(secureStorageProvider);
    await Supabase.instance.client.auth.signOut();
    await storage.delete(key: 'remember_session');
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'employee_id');
    await storage.delete(key: 'organization_id');
    await storage.delete(key: 'worksite_id');
    await storage.delete(key: 'employee_number');
    await storage.delete(key: 'employee_name');
    state = const AuthSession(initialized: true, authenticated: false);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthSession>(AuthController.new);

final connectivitySyncProvider = Provider<void>((ref) {
  final client = ref.watch(attendanceClientProvider);
  final subscription = Connectivity().onConnectivityChanged.listen((results) {
    if (results.any((result) => result != ConnectivityResult.none)) {
      unawaited(client.syncPending());
    }
  });
  ref.onDispose(subscription.cancel);
});
