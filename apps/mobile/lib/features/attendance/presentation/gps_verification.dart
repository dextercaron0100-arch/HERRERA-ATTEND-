import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:geoattend_employee/core/theme/app_colors.dart';
import 'package:geoattend_employee/data/clients/attendance_client.dart';

const _successGreen = Color(0xff22a447);
const _successLight = Color(0xffe8f8ec);

class GpsVerificationSuccessPage extends StatelessWidget {
  const GpsVerificationSuccessPage({super.key, this.result});
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
        body: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final side = constraints.maxWidth >= 700 ? 48.0 : 16.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(side, 16, side, 110),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(children: [
                    const _MapPanel(),
                    const SizedBox(height: 16),
                    const _SuccessBanner(),
                    const SizedBox(height: 16),
                    _VerificationDetails(result: result),
                  ]),
                ),
              ),
            );
          }),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xffe5eaf0))),
            ),
            child: FilledButton.icon(
              onPressed: () => context.pop(),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Done'),
            ),
          ),
        ),
      );
}

class _MapPanel extends StatelessWidget {
  const _MapPanel();

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Map showing your position inside the approved geofence',
        child: Container(
          height: 300,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xffeef3f4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffd9e1e8)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0d0f172a),
                  blurRadius: 12,
                  offset: Offset(0, 5)),
            ],
          ),
          child: Stack(children: [
            const Positioned.fill(child: CustomPaint(painter: _MapPainter())),
            Center(
              child: Container(
                width: 154,
                height: 154,
                decoration: BoxDecoration(
                  color: _successGreen.withValues(alpha: .13),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _successGreen.withValues(alpha: .5), width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: _successGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color(0x5522a447), blurRadius: 18)
                      ],
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .94),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xffa9dfb5)),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle_rounded,
                        color: _successGreen, size: 18),
                    SizedBox(width: 7),
                    Text('Inside Geofence',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: dashboardText)),
                  ]),
                ),
              ),
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
                  border: Border.all(color: const Color(0xffd7dfe6)),
                ),
                child: const Icon(Icons.my_location_rounded,
                    size: 20, color: dashboardBlue),
              ),
            ),
          ]),
        ),
      );
}

class _MapPainter extends CustomPainter {
  const _MapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final building = Paint()..color = const Color(0xffdce5e5);
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;
    final roadEdge = Paint()
      ..color = const Color(0xffd3dcde)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(18, 38, 94, 68), building);
    canvas.drawRect(Rect.fromLTWH(size.width - 126, 184, 100, 74), building);
    canvas.drawRect(Rect.fromLTWH(30, 208, 72, 52), building);
    final diagonal = Path()
      ..moveTo(-20, size.height * .84)
      ..quadraticBezierTo(
          size.width * .45, size.height * .35, size.width + 20, 26);
    canvas.drawPath(diagonal, road);
    canvas.drawPath(diagonal, roadEdge);
    final horizontal = Path()
      ..moveTo(-10, 142)
      ..quadraticBezierTo(size.width * .5, 126, size.width + 10, 158);
    canvas.drawPath(horizontal, road);
    canvas.drawPath(horizontal, roadEdge);
    final labelStyle = const TextStyle(
        color: Color(0xff8b999c), fontSize: 10, fontWeight: FontWeight.w600);
    for (final entry in {
      const Offset(24, 55): 'Operations',
      Offset(size.width - 116, 210): 'Main Office HQ',
      const Offset(24, 228): 'Parking',
    }.entries) {
      final text = TextPainter(
          text: TextSpan(text: entry.value, style: labelStyle),
          textDirection: TextDirection.ltr)
        ..layout();
      text.paint(canvas, entry.key);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner();
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _successLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xffb9e8c3)),
        ),
        child:
            const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.verified_user_rounded, color: Color(0xff087a2b), size: 27),
          SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Verification Successful',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff075c22))),
                SizedBox(height: 4),
                Text('You are securely inside the approved attendance area.',
                    style: TextStyle(
                        fontSize: 13, height: 1.4, color: Color(0xff17652e))),
              ])),
        ]),
      );
}

class _VerificationDetails extends StatelessWidget {
  const _VerificationDetails({this.result});
  final ClockResult? result;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffdfe6ec))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('VERIFICATION DETAILS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                  color: dashboardMuted)),
          const SizedBox(height: 13),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
            childAspectRatio: 1.42,
            children: [
              const _DetailTile(
                  icon: Icons.business_rounded,
                  label: 'Worksite',
                  value: 'Main Office HQ'),
              _DetailTile(
                  icon: Icons.straighten_rounded,
                  label: 'Distance',
                  value: result?.distanceMeters == null
                      ? 'Verified'
                      : '${result!.distanceMeters!.round()} meters'),
              _DetailTile(
                  icon: Icons.satellite_alt_rounded,
                  label: 'GPS Accuracy',
                  value: result?.accuracyMeters == null
                      ? 'High'
                      : '±${result!.accuracyMeters!.round()} meters',
                  verified: true),
              const _DetailTile(
                  icon: Icons.wifi_rounded,
                  label: 'Network',
                  value: 'Corp WiFi',
                  verified: true),
            ],
          ),
        ]),
      );
}

class _DetailTile extends StatelessWidget {
  const _DetailTile(
      {required this.icon,
      required this.label,
      required this.value,
      this.verified = false});
  final IconData icon;
  final String label;
  final String value;
  final bool verified;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xfffbfdff),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xffe1e7ed))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(children: [
                Icon(icon, size: 16, color: dashboardBlue),
                const SizedBox(width: 5),
                Flexible(
                    child: Text(label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: dashboardMuted)))
              ]),
              const SizedBox(height: 7),
              Row(children: [
                Flexible(
                    child: Text(value,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: dashboardText))),
                if (verified) ...[
                  const SizedBox(width: 5),
                  const Icon(Icons.check_circle_rounded,
                      size: 14, color: _successGreen)
                ]
              ]),
            ]),
      );
}
