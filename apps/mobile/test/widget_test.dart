import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoattend_employee/core/services/app_services.dart';
import 'package:geoattend_employee/main.dart';

class TestAuthController extends AuthController {
  @override
  AuthSession build() =>
      const AuthSession(initialized: true, authenticated: false);

  @override
  Future<bool> login(
      {required String username,
      required String password,
      required bool remember}) async {
    if (username != 'EMP-001' || password != 'Herrera123!') {
      return false;
    }
    state = const AuthSession(initialized: true, authenticated: true);
    return true;
  }
}

void main() {
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
    expect(find.textContaining('Employee ID: EMP-001'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'EMP-001');
    await tester.enterText(find.byType(TextFormField).at(1), 'Herrera123!');
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
