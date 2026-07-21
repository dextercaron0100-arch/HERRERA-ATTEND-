import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:geoattend_employee/core/services/app_services.dart';
import 'package:geoattend_employee/core/theme/app_colors.dart';
import 'package:geoattend_employee/data/clients/mobile_client.dart';

class LeaveDashboardPage extends ConsumerStatefulWidget {
  const LeaveDashboardPage({super.key});

  @override
  ConsumerState<LeaveDashboardPage> createState() => _LeaveDashboardPageState();
}

class _LeaveDashboardPageState extends ConsumerState<LeaveDashboardPage>
    with TickerProviderStateMixin {
  late AnimationController entrance;
  late AnimationController floating;

  @override
  void initState() {
    super.initState();
    entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 950))
      ..forward();
    floating = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    entrance.dispose();
    floating.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overviewState = ref.watch(mobileOverviewProvider);
    final overview = overviewState.asData?.value;
    final leaveRequests = overview?.requests
            .where((request) => request.type == 'LEAVE')
            .take(5)
            .toList() ??
        const <EmployeeRequest>[];
    return Scaffold(
      backgroundColor: const Color(0xfff6faff),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        shadowColor: const Color(0x140f172a),
        title: const Text('Leave Management',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        final side = wide ? 48.0 : 16.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(side, 20, side, 105),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('Your Leave',
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.6,
                                    color: Color(0xff031635))),
                            SizedBox(height: 4),
                            Text('Track balances and request time off.',
                                style: TextStyle(
                                    fontSize: 13, color: dashboardMuted)),
                          ])),
                      if (wide)
                        FilledButton.icon(
                            onPressed: () => context.push('/requests/new'),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Request Leave')),
                    ]),
                    const SizedBox(height: 22),
                    _Entrance(
                        controller: entrance,
                        start: 0,
                        child: _BalanceLayout(
                            wide: wide,
                            progress: entrance,
                            balances: overview?.leaveBalances)),
                    const SizedBox(height: 26),
                    _Entrance(
                        controller: entrance,
                        start: .28,
                        child: const Text('Recent Requests',
                            style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Color(0xff031635)))),
                    const SizedBox(height: 12),
                    if (overviewState.isLoading && overview == null)
                      const Center(child: CircularProgressIndicator())
                    else if (leaveRequests.isEmpty)
                      const _EmptyRequests()
                    else
                      for (var index = 0;
                          index < leaveRequests.length;
                          index++) ...[
                        _Entrance(
                          controller: entrance,
                          start: (.35 + index * .08).clamp(0, .7),
                          child: _RequestTile.fromRequest(leaveRequests[index]),
                        ),
                        if (index < leaveRequests.length - 1)
                          const SizedBox(height: 10),
                      ],
                  ]),
            ),
          ),
        );
      })),
      floatingActionButton: AnimatedBuilder(
        animation: floating,
        builder: (context, child) => Transform.translate(
            offset: Offset(0, -5 * floating.value), child: child),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/requests/new'),
          backgroundColor: const Color(0xff031635),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Request Leave',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _BalanceLayout extends StatelessWidget {
  const _BalanceLayout(
      {required this.wide, required this.progress, this.balances});
  final bool wide;
  final Animation<double> progress;
  final Map<String, int>? balances;
  @override
  Widget build(BuildContext context) {
    final cards = [
      _LeaveData(
          'Vacation',
          '${balances?['vacation'] ?? 0}',
          'Days Available',
          Icons.flight_takeoff_rounded,
          Color(0xff1d4e89),
          Color(0xffd8e2ff),
          .60),
      _LeaveData(
          'Sick',
          '${balances?['sick'] ?? 0}',
          'Days Available',
          Icons.medical_services_rounded,
          Color(0xffba1a1a),
          Color(0xffffdad6),
          .25),
      _LeaveData('Personal', '${balances?['personal'] ?? 0}', 'Days Available',
          Icons.person_rounded, Color(0xff16813a), Color(0xffd9f9df), .15),
    ];
    if (wide) {
      return Row(children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: _BalanceCard(data: cards[i], progress: progress)),
          if (i < cards.length - 1) const SizedBox(width: 12)
        ]
      ]);
    }
    return Column(children: [
      _BalanceCard(data: cards.first, progress: progress, prominent: true),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _BalanceCard(data: cards[1], progress: progress)),
        const SizedBox(width: 12),
        Expanded(child: _BalanceCard(data: cards[2], progress: progress))
      ]),
    ]);
  }
}

class _LeaveData {
  const _LeaveData(this.title, this.value, this.label, this.icon, this.color,
      this.background, this.ratio);
  final String title;
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color background;
  final double ratio;
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard(
      {required this.data, required this.progress, this.prominent = false});
  final _LeaveData data;
  final Animation<double> progress;
  final bool prominent;
  @override
  Widget build(BuildContext context) => Container(
        constraints: BoxConstraints(minHeight: prominent ? 150 : 158),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffdce4eb)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x090f172a),
                  blurRadius: 12,
                  offset: Offset(0, 5))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: data.background,
                    borderRadius: BorderRadius.circular(11)),
                child: Icon(data.icon, size: 20, color: data.color)),
            const SizedBox(width: 9),
            Flexible(
                child: Text(data.title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: dashboardText)))
          ]),
          const Spacer(),
          Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 5,
              children: [
                Text(data.value,
                    style: const TextStyle(
                        fontSize: 29,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: dashboardText)),
                Text(data.label,
                    style: const TextStyle(fontSize: 10, color: dashboardMuted))
              ]),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: progress,
            builder: (context, _) => ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: LinearProgressIndicator(
                    value: data.ratio *
                        Curves.easeOutCubic.transform(progress.value),
                    minHeight: 7,
                    backgroundColor: const Color(0xffe4ebf1),
                    valueColor: AlwaysStoppedAnimation(data.color))),
          ),
        ]),
      );
}

class _RequestTile extends StatefulWidget {
  const _RequestTile(
      {required this.icon,
      required this.iconColor,
      required this.iconBackground,
      required this.title,
      required this.dates,
      required this.status,
      required this.statusColor,
      required this.statusBackground});
  factory _RequestTile.fromRequest(EmployeeRequest request) {
    final approved = request.status == 'APPROVED';
    final rejected = request.status == 'REJECTED';
    return _RequestTile(
      icon: Icons.flight_takeoff_rounded,
      iconColor: const Color(0xff1d4e89),
      iconBackground: const Color(0xffd8e2ff),
      title: 'Leave Request',
      dates: '${_shortDate(request.startsAt)} – ${_shortDate(request.endsAt)}',
      status: request.status,
      statusColor: approved
          ? const Color(0xff087a2b)
          : rejected
              ? const Color(0xff93000a)
              : const Color(0xff9a5a00),
      statusBackground: approved
          ? const Color(0xffe6f8eb)
          : rejected
              ? const Color(0xffffdad6)
              : const Color(0xfffff0d1),
    );
  }
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String dates;
  final String status;
  final Color statusColor;
  final Color statusBackground;
  @override
  State<_RequestTile> createState() => _RequestTileState();
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests();
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffdfe6ec))),
        child: const Column(children: [
          Icon(Icons.event_available_outlined, color: dashboardMuted),
          SizedBox(height: 8),
          Text('No leave requests yet',
              style: TextStyle(color: dashboardMuted)),
        ]),
      );
}

String _shortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${months[date.month - 1]} ${date.day}';
}

class _RequestTileState extends State<_RequestTile> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: pressed ? .985 : 1,
        duration: const Duration(milliseconds: 120),
        child: GestureDetector(
          onTapDown: (_) => setState(() => pressed = true),
          onTapCancel: () => setState(() => pressed = false),
          onTapUp: (_) {
            setState(() => pressed = false);
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${widget.title} request details')));
          },
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xffdfe6ec))),
            child: Row(children: [
              Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: widget.iconBackground, shape: BoxShape.circle),
                  child: Icon(widget.icon, color: widget.iconColor, size: 21)),
              const SizedBox(width: 13),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(widget.title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: dashboardText)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 13, color: dashboardMuted),
                      const SizedBox(width: 5),
                      Text(widget.dates,
                          style: const TextStyle(
                              fontSize: 12, color: dashboardMuted))
                    ])
                  ])),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                      color: widget.statusBackground,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(widget.status,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .3,
                          color: widget.statusColor))),
            ]),
          ),
        ),
      );
}

class _Entrance extends StatelessWidget {
  const _Entrance(
      {required this.controller, required this.start, required this.child});
  final AnimationController controller;
  final double start;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
        parent: controller,
        curve: Interval(start, (start + .35).clamp(0, 1),
            curve: Curves.easeOutCubic));
    return FadeTransition(
        opacity: animation,
        child: SlideTransition(
            position: Tween(begin: const Offset(0, .12), end: Offset.zero)
                .animate(animation),
            child: child));
  }
}
