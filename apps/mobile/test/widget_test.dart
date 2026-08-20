import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoattend_employee/core/services/app_services.dart';
import 'package:geoattend_employee/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestAuthController extends AuthController {
  @override
  AuthSession build() =>
      const AuthSession(initialized: true, authenticated: false);

  @override
  Future<bool> login(
      {required String username,
      required String password,
      required bool remember}) async {
    if (username != 'employee@example.com' || password != 'ValidPass123!') {
      return false;
    }
    state = const AuthSession(initialized: true, authenticated: true);
    return true;
  }
}

class MemoryAsyncStorage extends GotrueAsyncStorage {
  final _values = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => _values[key];

  @override
  Future<void> removeItem({required String key}) async {
    _values.remove(key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    _values[key] = value;
  }
}

void main() {
  setUpAll(() async {
    await Supabase.initialize(
        url: 'https://example.supabase.co',
        publishableKey: 'sb_publishable_test',
        authOptions: FlutterAuthClientOptions(
            localStorage: const EmptyLocalStorage(),
            pkceAsyncStorage: MemoryAsyncStorage()));
  });

  tearDownAll(() async {
    await Supabase.instance.dispose();
  });

  testWidgets('shows splash, login, then employee clock action',
      (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      connectivitySyncProvider.overrideWithValue(null),
      authControllerProvider.overrideWith(TestAuthController.new),
    ], child: const GeoAttendApp()));
    expect(find.text('HERRERA ATTEND'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('WORK EMAIL'), findsOneWidget);
    await tester.enterText(
        find.byType(TextFormField).at(0), 'employee@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'ValidPass123!');
    final loginButton = find.widgetWithText(FilledButton, 'Login');
    await tester.ensureVisible(loginButton);
    await tester.pump();
    await tester.tap(loginButton);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('CLOCK IN'), findsOneWidget);
    expect(find.text('DAYS PRESENT'), findsOneWidget);
  });
}
