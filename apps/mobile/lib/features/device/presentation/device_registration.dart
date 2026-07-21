import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:geoattend_employee/core/services/app_services.dart';
import 'package:geoattend_employee/core/theme/app_colors.dart';

class DeviceRegistrationPage extends ConsumerStatefulWidget {
  const DeviceRegistrationPage({super.key});

  @override
  ConsumerState<DeviceRegistrationPage> createState() =>
      _DeviceRegistrationPageState();
}

class _DeviceRegistrationPageState extends ConsumerState<DeviceRegistrationPage>
    with TickerProviderStateMixin {
  final deviceName = TextEditingController(text: 'Android Device');
  final digits = List.generate(6, (_) => TextEditingController());
  final focuses = List.generate(6, (_) => FocusNode());
  late AnimationController entrance;
  late AnimationController pulse;
  final bool biometrics = true;
  bool submitting = false;
  String? error;

  @override
  void initState() {
    super.initState();
    entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1700))
      ..repeat();
  }

  @override
  void dispose() {
    deviceName.dispose();
    for (final item in digits) {
      item.dispose();
    }
    for (final item in focuses) {
      item.dispose();
    }
    entrance.dispose();
    pulse.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final code = digits.map((item) => item.text).join();
    if (deviceName.text.trim().length < 3) {
      setState(() => error = 'Enter a device name.');
      return;
    }
    if (code.length != 6) {
      setState(() => error = 'Enter the 6-digit verification code.');
      return;
    }
    setState(() {
      submitting = true;
      error = null;
    });
    try {
      final storage = ref.read(secureStorageProvider);
      final employeeId = await storage.read(key: 'employee_id');
      if (employeeId == null) throw Exception('Please sign in again.');
      final existingId = await storage.read(key: 'device_id');
      final deviceId = existingId ?? 'android-${const Uuid().v4()}';
      await ref.read(dioProvider).post('/mobile/devices/register', data: {
        'employeeId': employeeId,
        'deviceId': deviceId,
        'name': deviceName.text.trim(),
        'platform': 'android',
        'biometricsEnabled': biometrics,
        'verificationCode': code,
      });
      await storage.write(key: 'device_registered', value: 'true');
      await storage.write(key: 'device_name', value: deviceName.text.trim());
      await storage.write(key: 'device_id', value: deviceId);
      await storage.write(key: 'biometrics_enabled', value: '$biometrics');
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        submitting = false;
        error = exception.toString().replaceFirst('Exception: ', '');
      });
      return;
    }
    if (!mounted) return;
    setState(() => submitting = false);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.verified_user_rounded,
            color: Color(0xff16813a), size: 42),
        title: const Text('Device Registered'),
        content: const Text(
            'This device is now secured for HERRERA ATTEND attendance.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'))
        ],
      ),
    );
    if (mounted) context.pop(true);
  }

  void onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < focuses.length - 1) {
      focuses[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) focuses[index - 1].requestFocus();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xfff6faff),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          title: const Text('HERRERA ATTEND',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff031635))),
          centerTitle: true,
        ),
        body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
          final side = constraints.maxWidth >= 700 ? 48.0 : 16.0;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(side, 20, side, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(children: [
                  _Entrance(
                    controller: entrance,
                    start: 0,
                    scale: true,
                    child: Column(children: [
                      AnimatedBuilder(
                        animation: pulse,
                        builder: (context, child) => Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.scale(
                              scale: .85 + pulse.value * .5,
                              child: Opacity(
                                opacity: 1 - pulse.value,
                                child: Container(
                                    width: 76,
                                    height: 76,
                                    decoration: const BoxDecoration(
                                        color: Color(0xffd8e2ff),
                                        shape: BoxShape.circle)),
                              ),
                            ),
                            child!,
                          ],
                        ),
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                              color: Color(0xff1a2b4b), shape: BoxShape.circle),
                          child: const Icon(Icons.phonelink_lock_rounded,
                              color: Color(0xffd8e2ff), size: 33),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text('Register Device',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.5,
                              color: dashboardText)),
                      const SizedBox(height: 5),
                      const Text(
                          'Secure your account by registering this device.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 13, color: dashboardMuted)),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xffdfe6ec)),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x0a0f172a),
                            blurRadius: 14,
                            offset: Offset(0, 6))
                      ],
                    ),
                    child: Column(children: [
                      _Entrance(
                        controller: entrance,
                        start: .10,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: const Color(0xffecf5fe),
                              borderRadius: BorderRadius.circular(13),
                              border:
                                  Border.all(color: const Color(0xffdbe4ed))),
                          child: const Row(children: [
                            Icon(Icons.info_rounded,
                                size: 21, color: Color(0xff031635)),
                            SizedBox(width: 10),
                            Expanded(
                                child: Text(
                                    'Only registered devices can record attendance securely.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        height: 1.4,
                                        color: dashboardMuted))),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 17),
                      _Entrance(
                        controller: entrance,
                        start: .20,
                        child: TextField(
                          controller: deviceName,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                              labelText: 'Device Name',
                              prefixIcon: Icon(Icons.smartphone_rounded),
                              hintText: 'e.g., Samsung Galaxy'),
                        ),
                      ),
                      const SizedBox(height: 17),
                      _Entrance(
                        controller: entrance,
                        start: .30,
                        child: const _IdentityCard(),
                      ),
                      const SizedBox(height: 20),
                      _Entrance(
                        controller: entrance,
                        start: .40,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Expanded(
                                    child: Text('VERIFICATION CODE',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: .6,
                                            color: dashboardText))),
                                TextButton(
                                  onPressed: () => ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                          content: Text(
                                              'Test code resent: 123456'))),
                                  child: const Text('Resend Code'),
                                ),
                              ]),
                              const Text('Enter the 6-digit test code 123456.',
                                  style: TextStyle(
                                      fontSize: 12, color: dashboardMuted)),
                              const SizedBox(height: 11),
                              Row(children: [
                                for (var i = 0; i < 6; i++) ...[
                                  Expanded(
                                      child: _OtpField(
                                          controller: digits[i],
                                          focusNode: focuses[i],
                                          onChanged: (value) =>
                                              onDigitChanged(i, value))),
                                  if (i < 5) const SizedBox(width: 7),
                                ],
                              ]),
                            ]),
                      ),
                      const SizedBox(height: 18),
                      _Entrance(
                        controller: entrance,
                        start: .52,
                        child: Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                              color: const Color(0xfffbfdff),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: const Color(0xffdfe6ec))),
                          child: const ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.verified_user_rounded,
                                color: Color(0xff031635)),
                            title: Text('Strong biometrics required',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w800)),
                            subtitle: Text(
                                'Face or fingerprint verification is enforced for every attendance action.',
                                style: TextStyle(
                                    fontSize: 11, color: dashboardMuted)),
                            trailing: Icon(Icons.lock_rounded,
                                color: Color(0xff16813a)),
                          ),
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xffba1a1a))),
                      ],
                      const SizedBox(height: 18),
                      _Entrance(
                        controller: entrance,
                        start: .62,
                        child: FilledButton.icon(
                          onPressed: submitting ? null : register,
                          icon: submitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.verified_user_rounded),
                          label: Text(submitting
                              ? 'Registering...'
                              : 'Register Device'),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          );
        })),
      );
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard();
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('IDENTITY CONFIRMATION',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .6,
                  color: dashboardText)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xffecf5fe),
                borderRadius: BorderRadius.circular(14)),
            child: const Row(children: [
              CircleAvatar(
                  radius: 21,
                  backgroundColor: Color(0xffd8e2ff),
                  child: Text('MS',
                      style: TextStyle(
                          color: Color(0xff031635),
                          fontWeight: FontWeight.w800,
                          fontSize: 12))),
              SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Maria Santos',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                SizedBox(height: 3),
                Text('EMP-001 • Operations',
                    style: TextStyle(fontSize: 11, color: dashboardMuted)),
              ]),
            ]),
          ),
        ],
      );
}

class _OtpField extends StatelessWidget {
  const _OtpField(
      {required this.controller,
      required this.focusNode,
      required this.onChanged});
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
        onChanged: onChanged,
      );
}

class _Entrance extends StatelessWidget {
  const _Entrance(
      {required this.controller,
      required this.start,
      required this.child,
      this.scale = false});
  final AnimationController controller;
  final double start;
  final Widget child;
  final bool scale;
  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
        parent: controller,
        curve: Interval(start, (start + .32).clamp(0, 1),
            curve: Curves.easeOutCubic));
    if (scale) {
      return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
              scale: Tween(begin: .86, end: 1.0).animate(animation),
              child: child));
    }
    return FadeTransition(
        opacity: animation,
        child: SlideTransition(
            position: Tween(begin: const Offset(0, .10), end: Offset.zero)
                .animate(animation),
            child: child));
  }
}
