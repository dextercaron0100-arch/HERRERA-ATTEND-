import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend_employee/core/services/app_services.dart';
import 'package:geoattend_employee/data/clients/attendance_client.dart';
import 'package:geoattend_employee/features/attendance/presentation/attendance_history.dart';
import 'package:geoattend_employee/features/attendance/presentation/attendance_home.dart';
import 'package:geoattend_employee/features/attendance/presentation/gps_verification.dart';
import 'package:geoattend_employee/features/attendance/presentation/gps_verification_error.dart';
import 'package:geoattend_employee/features/auth/presentation/auth_screens.dart';
import 'package:geoattend_employee/features/device/presentation/device_registration.dart';
import 'package:geoattend_employee/features/leave/presentation/leave_dashboard.dart';
import 'package:geoattend_employee/features/leave/presentation/request_page.dart';
import 'package:geoattend_employee/features/payroll/presentation/payroll_dashboard.dart';
import 'package:geoattend_employee/features/profile/presentation/notifications_page.dart';
import 'package:geoattend_employee/features/profile/presentation/profile_page.dart';
import 'package:geoattend_employee/features/profile/presentation/readiness_page.dart';
import 'package:geoattend_employee/features/schedule/presentation/monthly_schedule.dart';
import 'package:geoattend_employee/features/schedule/presentation/weekly_schedule.dart';

void main() => runApp(const ProviderScope(child: GeoAttendApp()));

CustomTransitionPage<void> _appPage(GoRouterState state, Widget child,
        {bool emphasized = false}) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: Duration(milliseconds: emphasized ? 520 : 380),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
          return child;
        }
        final curved = CurvedAnimation(
            parent: animation,
            curve: emphasized ? Curves.easeOutQuart : Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
                    begin: Offset(0, emphasized ? .045 : .025),
                    end: Offset.zero)
                .animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: .985, end: 1).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );

final routerProvider = Provider<GoRouter>((ref) => GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
            path: '/splash',
            pageBuilder: (context, state) =>
                _appPage(state, SplashScreen(onFinished: () {
                  final session = ref.read(authControllerProvider);
                  context.go(session.authenticated ? '/clock' : '/login');
                }), emphasized: true)),
        GoRoute(
            path: '/login',
            pageBuilder: (context, state) => _appPage(
                state,
                LoginScreen(
                  onLogin: (username, password, remember) async {
                    final accepted = await ref
                        .read(authControllerProvider.notifier)
                        .login(
                            username: username,
                            password: password,
                            remember: remember);
                    if (accepted && context.mounted) context.go('/clock');
                    return accepted;
                  },
                  onBiometric: () async {
                    final authenticated = await ref
                        .read(authControllerProvider.notifier)
                        .biometricLogin();
                    if (authenticated && context.mounted) context.go('/clock');
                    return authenticated;
                  },
                ),
                emphasized: true)),
        GoRoute(
            path: '/clock',
            pageBuilder: (context, state) =>
                _appPage(state, const ClockPage(), emphasized: true)),
        GoRoute(
            path: '/history',
            pageBuilder: (context, state) =>
                _appPage(state, const AttendanceHistoryPage())),
        GoRoute(
            path: '/payroll',
            pageBuilder: (context, state) =>
                _appPage(state, const PayrollDashboardPage())),
        GoRoute(
            path: '/schedule',
            pageBuilder: (context, state) =>
                _appPage(state, const WeeklySchedulePage())),
        GoRoute(
            path: '/schedule/month',
            pageBuilder: (context, state) =>
                _appPage(state, const MonthlySchedulePage())),
        GoRoute(
            path: '/leave',
            pageBuilder: (context, state) =>
                _appPage(state, const LeaveDashboardPage())),
        GoRoute(
            path: '/gps-verification',
            pageBuilder: (context, state) => _appPage(
                state,
                GpsVerificationSuccessPage(
                    result: state.extra is ClockResult
                        ? state.extra! as ClockResult
                        : null))),
        GoRoute(
            path: '/gps-verification-error',
            pageBuilder: (context, state) => _appPage(
                state,
                GpsVerificationErrorPage(
                    result: state.extra is ClockResult
                        ? state.extra! as ClockResult
                        : null))),
        GoRoute(
            path: '/device-registration',
            pageBuilder: (context, state) =>
                _appPage(state, const DeviceRegistrationPage())),
        GoRoute(
            path: '/requests/new',
            pageBuilder: (context, state) =>
                _appPage(state, const RequestPage())),
        GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                _appPage(state, const ProfilePage())),
        GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) =>
                _appPage(state, const NotificationsPage())),
        GoRoute(
            path: '/readiness',
            pageBuilder: (context, state) =>
                _appPage(state, const ReadinessPage())),
      ],
    ));

class GeoAttendApp extends ConsumerWidget {
  const GeoAttendApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(connectivitySyncProvider);
    return MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'HERRERA ATTEND',
        theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: geoNavy, surface: geoBackground),
            scaffoldBackgroundColor: geoBackground,
            inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 17, horizontal: 16),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xffc5c6cf))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xffc5c6cf))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: geoNavy, width: 2))),
            filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                    backgroundColor: geoNavy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700))),
            outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                    foregroundColor: geoNavy,
                    backgroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    side: const BorderSide(color: Color(0xffc5c6cf)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700))),
            textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: geoNavy)),
            useMaterial3: true),
        routerConfig: ref.watch(routerProvider));
  }
}
