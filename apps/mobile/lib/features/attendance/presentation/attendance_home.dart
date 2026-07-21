import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend_employee/core/services/app_services.dart';
import 'package:geoattend_employee/core/theme/app_colors.dart';
import 'package:geoattend_employee/data/clients/mobile_client.dart';

class ClockPage extends ConsumerStatefulWidget {
  const ClockPage({super.key});
  @override
  ConsumerState<ClockPage> createState() => _ClockPageState();
}

class _ClockPageState extends ConsumerState<ClockPage> {
  late DateTime now;
  Timer? timer;
  bool clockedIn = false;
  bool submitting = false;
  String status = 'Location will be verified when you clock in.';

  @override
  void initState() {
    super.initState();
    now = DateTime.now();
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => now = DateTime.now());
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> clock() async {
    final verified = await ref
        .read(authControllerProvider.notifier)
        .verifyStrongBiometric(
            reason: clockedIn
                ? 'Verify your identity before clocking out'
                : 'Verify your identity before clocking in');
    if (!verified) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Strong face or fingerprint verification is required to record attendance.')));
      }
      return;
    }
    final wasClockedIn = clockedIn;
    setState(() => submitting = true);
    final result = await ref
        .read(attendanceClientProvider)
        .submit(clockedIn ? 'CLOCK_OUT' : 'CLOCK_IN');
    if (!mounted) {
      return;
    }
    setState(() {
      submitting = false;
      status = _friendlyStatus(result.decision, result.reasonCodes);
      if (result.decision == 'ACCEPTED' || result.queued) {
        clockedIn = !clockedIn;
      }
    });
    if (result.decision == 'ACCEPTED' && !wasClockedIn && mounted) {
      await context.push('/gps-verification', extra: result);
    }
    if (result.decision == 'REJECTED' && mounted) {
      final retry =
          await context.push<bool>('/gps-verification-error', extra: result);
      if (retry == true && mounted) await clock();
    }
    if (result.decision == 'CONFIGURATION_REQUIRED' && mounted) {
      await context.push<bool>('/device-registration');
    }
  }

  String _friendlyStatus(String decision, List<String> reasons) {
    if (decision == 'ACCEPTED') {
      return clockedIn
          ? 'Clock-out recorded successfully.'
          : 'Clock-in recorded successfully.';
    }
    if (decision == 'QUEUED') {
      return 'Saved offline and waiting to synchronize.';
    }
    if (decision == 'CONFIGURATION_REQUIRED') {
      return 'Employee setup is required on this device.';
    }
    return reasons.isEmpty
        ? decision
        : reasons.join(' · ').replaceAll('_', ' ').toLowerCase();
  }

  String get formattedTime {
    var hour = now.hour;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $suffix';
  }

  String get formattedDate {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
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
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  void navMessage(String label) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$label will be available in the next mobile phase.')));

  @override
  Widget build(BuildContext context) {
    final overviewState = ref.watch(mobileOverviewProvider);
    final overview = overviewState.asData?.value;
    final employee = overview?.employee;
    final initials = (employee?.name ?? 'Maria Santos')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join();
    return Scaffold(
      backgroundColor: dashboardBackground,
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        shadowColor: const Color(0x140f172a),
        titleSpacing: 20,
        title: Row(children: [
          CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xffdbeafe),
              child: Text(initials,
                  style: const TextStyle(
                      color: dashboardBlue,
                      fontWeight: FontWeight.w800,
                      fontSize: 13))),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Welcome back,',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: dashboardMuted)),
            const SizedBox(height: 2),
            Text(employee?.name ?? 'Maria Santos',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: dashboardText)),
          ]),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Badge(
              smallSize: 8,
              backgroundColor: const Color(0xffef4444),
              child: IconButton.filledTonal(
                  onPressed: () => context.push('/notifications'),
                  tooltip: 'Open notifications',
                  icon: const Icon(Icons.notifications_none_rounded)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(builder: (context, constraints) {
          final padding = constraints.maxWidth >= 700 ? 48.0 : 18.0;
          WorkShift? todayShift;
          for (final shift in overview?.shifts ?? const <WorkShift>[]) {
            if (shift.dayOfWeek == now.weekday) todayShift = shift;
          }
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(padding, 18, padding, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(children: [
                  _TodayCard(
                    date: formattedDate,
                    time: formattedTime,
                    location: employee?.worksite?.name ?? 'Worksite not set',
                    shift: todayShift == null
                        ? 'No scheduled shift'
                        : '${_minuteTime(todayShift.startMinute)} – ${_minuteTime(todayShift.endMinute)}',
                    clockedIn: clockedIn,
                    submitting: submitting,
                    status: status,
                    onClock: clock,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                      title: 'This month',
                      action: 'View history',
                      onTap: () => context.push('/history')),
                  const SizedBox(height: 10),
                  if (overviewState.isLoading && overview == null)
                    const LinearProgressIndicator(minHeight: 2)
                  else
                    _StatsGrid(overview: overview),
                  const SizedBox(height: 22),
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Quick actions',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: dashboardText))),
                  const SizedBox(height: 11),
                  Row(children: [
                    Expanded(
                        child: _QuickAction(
                            icon: Icons.calendar_today_rounded,
                            label: 'Schedule',
                            onTap: () => context.push('/schedule'))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _QuickAction(
                            icon: Icons.beach_access_rounded,
                            label: 'Request leave',
                            onTap: () => context.push('/requests/new'))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _QuickAction(
                            icon: Icons.receipt_long_rounded,
                            label: 'Payslip',
                            onTap: () => context.push('/payroll'))),
                  ]),
                ]),
              ),
            ),
          );
        }),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xffeff6ff),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          if (index == 1) context.push('/schedule');
          if (index == 2) context.push('/history');
          if (index == 3) context.push('/payroll');
          if (index == 4) context.push('/profile');
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined), label: 'Schedule'),
          NavigationDestination(
              icon: Icon(Icons.history_rounded), label: 'History'),
          NavigationDestination(
              icon: Icon(Icons.payments_outlined),
              selectedIcon: Icon(Icons.payments_rounded),
              label: 'Payroll'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

String _minuteTime(int minute) {
  final hour24 = minute ~/ 60;
  final hour = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
  return '$hour:${(minute % 60).toString().padLeft(2, '0')} ${hour24 >= 12 ? 'PM' : 'AM'}';
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.date,
    required this.time,
    required this.location,
    required this.shift,
    required this.clockedIn,
    required this.submitting,
    required this.status,
    required this.onClock,
  });
  final String date;
  final String time;
  final String location;
  final String shift;
  final bool clockedIn;
  final bool submitting;
  final String status;
  final VoidCallback onClock;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xff071a38), Color(0xff1d4e89)]),
          boxShadow: const [
            BoxShadow(
                color: Color(0x331d4e89), blurRadius: 24, offset: Offset(0, 12))
          ],
        ),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(date,
                      style: const TextStyle(
                          color: Color(0xffbdd2ed),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(time,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          height: 1.05,
                          letterSpacing: -1,
                          fontWeight: FontWeight.w800)),
                ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: const Color(0x20ffffff),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x25ffffff))),
              child: Row(children: [
                Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        color: clockedIn
                            ? const Color(0xff66df75)
                            : const Color(0xffbdd2ed),
                        shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(clockedIn ? 'On shift' : 'Not clocked in',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
                child: _TodayDetail(
                    icon: Icons.location_on_outlined,
                    label: 'WORKSITE',
                    value: location)),
            Container(width: 1, height: 38, color: const Color(0x26ffffff)),
            const SizedBox(width: 14),
            Expanded(
                child: _TodayDetail(
                    icon: Icons.schedule_rounded,
                    label: 'TODAY’S SHIFT',
                    value: shift)),
          ]),
          const SizedBox(height: 20),
          _ClockButton(
              clockedIn: clockedIn, submitting: submitting, onPressed: onClock),
          const SizedBox(height: 13),
          AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(status,
                  key: ValueKey(status),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xffd8e7f8), fontSize: 12, height: 1.35))),
        ]),
      );
}

class _TodayDetail extends StatelessWidget {
  const _TodayDetail(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: const Color(0xff9ac7ff), size: 20),
        const SizedBox(width: 8),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xff9fb6d3),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .6)),
          const SizedBox(height: 2),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ])),
      ]);
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(
      {required this.title, required this.action, required this.onTap});
  final String title;
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: dashboardText))),
        TextButton(onPressed: onTap, child: Text(action)),
      ]);
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xffe2e8f0))),
            child: Column(children: [
              Icon(icon, color: dashboardBlue, size: 23),
              const SizedBox(height: 7),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: dashboardText)),
            ]),
          ),
        ),
      );
}

class _ClockButton extends StatelessWidget {
  const _ClockButton(
      {required this.clockedIn,
      required this.submitting,
      required this.onPressed});
  final bool clockedIn;
  final bool submitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: clockedIn ? 'Clock out' : 'Clock in',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 156,
          height: 156,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: clockedIn ? const Color(0xff047857) : dashboardBlue,
              boxShadow: [
                BoxShadow(
                    color: (clockedIn ? const Color(0xff047857) : dashboardBlue)
                        .withValues(alpha: .34),
                    blurRadius: 20,
                    spreadRadius: 1)
              ]),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: submitting ? null : onPressed,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (submitting)
                      const SizedBox.square(
                          dimension: 45,
                          child: CircularProgressIndicator(
                              strokeWidth: 4, color: Colors.white))
                    else
                      Icon(
                          clockedIn
                              ? Icons.logout_rounded
                              : Icons.fingerprint_rounded,
                          size: 42,
                          color: Colors.white),
                    const SizedBox(height: 10),
                    Text(clockedIn ? 'CLOCK OUT' : 'CLOCK IN',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            letterSpacing: .8,
                            fontWeight: FontWeight.w800)),
                  ]),
            ),
          ),
        ),
      );
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({this.overview});
  final MobileOverview? overview;

  @override
  Widget build(BuildContext context) {
    final current = DateTime.now();
    final summaries = overview?.summaries
            .where((item) =>
                item.localDate.year == current.year &&
                item.localDate.month == current.month)
            .toList() ??
        const <AttendanceSummaryInfo>[];
    final stats = [
      _StatData(Icons.event_available_rounded, const Color(0xff2563eb),
          const Color(0xffdbeafe), '${summaries.length}', 'DAYS PRESENT'),
      _StatData(
          Icons.schedule_rounded,
          const Color(0xffd97706),
          const Color(0xffffedd5),
          '${summaries.where((item) => item.lateMinutes > 0).length}',
          'LATE ARRIVALS'),
      _StatData(
          Icons.beach_access_rounded,
          const Color(0xff7c3aed),
          const Color(0xffede9fe),
          '${overview?.leaveBalances['vacation'] ?? 0}',
          'LEAVE BALANCE'),
      _StatData(
          Icons.work_history_rounded,
          const Color(0xff059669),
          const Color(0xffd1fae5),
          '${(summaries.fold<int>(0, (sum, item) => sum + item.workedMinutes) / 60).toStringAsFixed(1)}h',
          'TOTAL HOURS'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 13,
          mainAxisSpacing: 13,
          childAspectRatio: 1.48),
      itemBuilder: (context, index) => _StatCard(data: stats[index]),
    );
  }
}

class _StatData {
  const _StatData(
      this.icon, this.color, this.background, this.value, this.label);
  final IconData icon;
  final Color color;
  final Color background;
  final String value;
  final String label;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});
  final _StatData data;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap:
            data.label == 'LEAVE BALANCE' ? () => context.push('/leave') : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xfff1f5f9)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0a0f172a),
                    blurRadius: 12,
                    offset: Offset(0, 5))
              ]),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: data.background, shape: BoxShape.circle),
                  child: Icon(data.icon, color: data.color, size: 18)),
            ]),
            const Spacer(),
            Text(data.value,
                style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: dashboardText)),
            const SizedBox(height: 3),
            Text(data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: .65,
                    fontWeight: FontWeight.w700,
                    color: dashboardMuted)),
          ]),
        ),
      );
}
