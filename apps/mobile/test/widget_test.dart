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
  Future<String?> login(
      {required String username,
      required String password,
      required bool remember}) async {
    if (username != 'employee@example.com' || password != 'ValidPass123!') {
      return 'Incorrect work email or password.';
    }
    state = const AuthSession(initialized: true, authenticated: true);
    return null;
  }
}

class ForcedResetAuthController extends TestAuthController {
  @override
  Future<String?> login(
      {required String username,
      required String password,
      required bool remember}) async {
    final error = await super
        .login(username: username, password: password, remember: remember);
    if (error == null) {
      state = const AuthSession(
          initialized: true,
          authenticated: true,
          passwordResetRequired: true);
    }
    return error;
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

  testWidgets('requires a new password after temporary-password login',
      (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      connectivitySyncProvider.overrideWithValue(null),
      authControllerProvider.overrideWith(ForcedResetAuthController.new),
    ], child: const GeoAttendApp()));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.enterText(
        find.byType(TextFormField).at(0), 'employee@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'ValidPass123!');
    final loginButton = find.widgetWithText(FilledButton, 'Login');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('Choose a new password'), findsOneWidget);
    expect(find.text('Set new password'), findsOneWidget);
    expect(find.text('CLOCK IN'), findsNothing);
  });
}
