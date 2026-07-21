import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:geoattend_employee/core/theme/app_colors.dart';
import 'package:geoattend_employee/data/clients/attendance_client.dart';

const _errorRed = Color(0xffba1a1a);

class GpsVerificationErrorPage extends StatelessWidget {
  const GpsVerificationErrorPage({super.key, this.result});
  final ClockResult? result;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xfff6faff),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 1,
          shadowColor: const Color(0x140f172a),
          title: const Text('Location Verification',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          centerTitle: true,
        ),
        body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
          final side = constraints.maxWidth >= 700 ? 48.0 : 16.0;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(side, 16, side, 30),
            child: Center(
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(children: [
                const _ErrorBanner(),
                const SizedBox(height: 16),
                const _OutsideMap(),
                const SizedBox(height: 16),
                _ErrorDetails(result: result),
                const SizedBox(height: 22),
                FilledButton.icon(
                    onPressed: () => context.pop(true),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh Location')),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                    onPressed: () => context.push('/requests/new'),
                    icon: const Icon(Icons.directions_walk_rounded),
                    label: const Text('Request Field Attendance')),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Supervisor contact request sent.'))),
                  icon: const Icon(Icons.contact_support_outlined),
                  label: const Text('Contact Supervisor'),
                ),
              ]),
            )),
          );
        })),
      );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner();
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xffffe7e3),
            borderRadius: BorderRadius.circular(18),
            border: const Border(left: BorderSide(color: _errorRed, width: 4))),
        child:
            const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.error_rounded, color: _errorRed, size: 27),
          SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Outside Approved Area',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _errorRed)),
                SizedBox(height: 4),
                Text('You are outside the approved attendance area.',
                    style: TextStyle(fontSize: 13, color: Color(0xff7c2725))),
              ])),
        ]),
      );
}

class _OutsideMap extends StatelessWidget {
  const _OutsideMap();
  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Map showing your position outside the approved geofence',
        child: Container(
          height: 275,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
              color: const Color(0xffe8eef0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xffcfd8de))),
          child: Stack(children: [
            const Positioned.fill(
                child: CustomPaint(painter: _ErrorMapPainter())),
            Positioned(
              right: 36,
              top: 62,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                    color: const Color(0x2522a447),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xaa22a447), width: 2)),
                child: const Icon(Icons.business_rounded,
                    color: Color(0xff087a2b), size: 30),
              ),
            ),
            Positioned(
              left: 58,
              bottom: 52,
              child: Column(children: [
                Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                        color: dashboardBlue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0x44214e89), blurRadius: 14)
                        ]),
                    child: const Icon(Icons.person_pin_circle_rounded,
                        color: Colors.white, size: 29)),
                const SizedBox(height: 3),
                Container(
                    width: 9,
                    height: 4,
                    decoration: BoxDecoration(
                        color: dashboardBlue.withValues(alpha: .3),
                        borderRadius: BorderRadius.circular(8))),
              ]),
            ),
            Positioned(
                right: 14,
                bottom: 14,
                child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xffd0d9df))),
                    child: const Icon(Icons.my_location_rounded,
                        size: 20, color: dashboardBlue))),
          ]),
        ),
      );
}

class _ErrorMapPainter extends CustomPainter {
  const _ErrorMapPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final blocks = Paint()..color = const Color(0xffd3dcdf);
    final road = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 17;
    final edge = Paint()
      ..color = const Color(0xffc6d0d4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(const Rect.fromLTWH(18, 28, 104, 58), blocks);
    canvas.drawRect(Rect.fromLTWH(size.width - 126, 202, 94, 52), blocks);
    canvas.drawRect(const Rect.fromLTWH(20, 190, 76, 46), blocks);
    final first = Path()
      ..moveTo(-10, 220)
      ..quadraticBezierTo(size.width * .45, 130, size.width + 10, 44);
    canvas.drawPath(first, road);
    canvas.drawPath(first, edge);
    final second = Path()
      ..moveTo(130, -10)
      ..quadraticBezierTo(size.width * .36, 145, 170, size.height + 10);
    canvas.drawPath(second, road);
    canvas.drawPath(second, edge);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ErrorDetails extends StatelessWidget {
  const _ErrorDetails({this.result});
  final ClockResult? result;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffdfe6ec))),
        child: Column(children: [
          const _DetailRow(
              icon: Icons.domain_rounded,
              label: 'WORKSITE',
              value: 'Main Office HQ'),
          const Divider(height: 28, color: Color(0xffe8edf1)),
          _DetailRow(
              icon: Icons.route_rounded,
              label: 'DISTANCE',
              value: result?.distanceMeters == null
                  ? 'Outside area'
                  : '${(result!.distanceMeters! / 1000).toStringAsFixed(1)} km away',
              error: true),
          const SizedBox(height: 18),
          Text(
              result?.reasonCodes.contains('LOCATION_PERMISSION_DENIED') == true
                  ? 'Enable location services and permission, then try again.'
                  : 'Please move closer to the workplace to clock in.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, height: 1.4, color: dashboardMuted)),
        ]),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.error = false});
  final IconData icon;
  final String label;
  final String value;
  final bool error;
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: dashboardMuted, size: 20),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
                color: dashboardMuted)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: error ? _errorRed : dashboardText)),
      ]);
}
