import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:geoattend_employee/core/services/app_services.dart';
import 'package:geoattend_employee/core/theme/app_colors.dart';
import 'package:geoattend_employee/data/clients/mobile_client.dart';

enum AttendanceStatus { present, late, absent }

class AttendanceHistoryPage extends ConsumerStatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  ConsumerState<AttendanceHistoryPage> createState() =>
      _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends ConsumerState<AttendanceHistoryPage> {
  late DateTime month;
  late DateTime selectedDay;
  Set<AttendanceStatus> filters = AttendanceStatus.values.toSet();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    month = DateTime(now.year, now.month);
    selectedDay = DateTime(now.year, now.month, now.day);
  }

  String get monthLabel {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${names[month.month - 1]} ${month.year}';
  }

  void changeMonth(int offset) {
    setState(() {
      month = DateTime(month.year, month.month + offset);
      selectedDay = DateTime(month.year, month.month, 1);
    });
  }

  Future<void> showFilters() async {
    final updated = await showModalBottomSheet<Set<AttendanceStatus>>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        var selected = {...filters};
        return StatefulBuilder(
            builder: (context, setSheetState) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Filter attendance',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          for (final status in AttendanceStatus.values)
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(_statusLabel(status)),
                              secondary: _StatusDot(status: status),
                              value: selected.contains(status),
                              onChanged: (value) => setSheetState(() =>
                                  value == true
                                      ? selected.add(status)
                                      : selected.remove(status)),
                            ),
                          const SizedBox(height: 8),
                          FilledButton(
                              onPressed: () => Navigator.pop(context, selected),
                              child: const Text('Apply filters')),
                        ]),
                  ),
                ));
      },
    );
    if (updated != null) setState(() => filters = updated);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mobileOverviewProvider);
    final overview = state.asData?.value;
    final statuses = <int, AttendanceStatus>{};
    for (final summary
        in overview?.summaries ?? const <AttendanceSummaryInfo>[]) {
      if (summary.localDate.year == month.year &&
          summary.localDate.month == month.month) {
        statuses[summary.localDate.day] = summary.lateMinutes > 0
            ? AttendanceStatus.late
            : AttendanceStatus.present;
      }
    }
    final selectedEvents = (overview?.events ?? const <AttendanceEventInfo>[])
        .where((event) => _sameDate(event.capturedAt, selectedDay))
        .toList()
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    return Scaffold(
      backgroundColor: dashboardBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        shadowColor: const Color(0x140f172a),
        title: const Text('Attendance History',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: showFilters,
              tooltip: 'Filter attendance',
              icon: const Icon(Icons.filter_list_rounded))
        ],
      ),
      body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 700 ? 48.0 : 16.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 28),
          child: Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                IconButton(
                    onPressed: () => changeMonth(-1),
                    icon: const Icon(Icons.chevron_left_rounded)),
                Text(monthLabel,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: dashboardText)),
                IconButton(
                    onPressed: () => changeMonth(1),
                    icon: const Icon(Icons.chevron_right_rounded)),
              ]),
              _CalendarCard(
                month: month,
                selectedDay: selectedDay,
                statuses: statuses,
                filters: filters,
                onSelected: (day) => setState(() => selectedDay = day),
              ),
              const SizedBox(height: 24),
              Text(
                  'Detailed Records (${_shortMonth(month.month)} ${selectedDay.day})',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: dashboardText)),
              const SizedBox(height: 12),
              if (selectedEvents.isEmpty)
                const _EmptyRecord(message: 'No attendance activity recorded.')
              else
                for (var index = 0; index < selectedEvents.length; index++) ...[
                  _RecordCard(
                      icon: _eventIcon(selectedEvents[index].kind),
                      iconColor: selectedEvents[index].decision == 'ACCEPTED'
                          ? const Color(0xff10b981)
                          : const Color(0xffba1a1a),
                      iconBackground:
                          selectedEvents[index].decision == 'ACCEPTED'
                              ? const Color(0xffecfdf5)
                              : const Color(0xffffdad6),
                      title: _eventTitle(selectedEvents[index].kind),
                      time: _time(selectedEvents[index].capturedAt)),
                  if (index < selectedEvents.length - 1)
                    const SizedBox(height: 12),
                ],
            ]),
          )),
        );
      })),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard(
      {required this.month,
      required this.selectedDay,
      required this.statuses,
      required this.filters,
      required this.onSelected});
  final DateTime month;
  final DateTime selectedDay;
  final Map<int, AttendanceStatus> statuses;
  final Set<AttendanceStatus> filters;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final days = DateTime(month.year, month.month + 1, 0).day;
    final leading = DateTime(month.year, month.month, 1).weekday % 7;
    final cells = ((leading + days + 6) ~/ 7) * 7;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xffeef2f7)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0a0f172a), blurRadius: 14, offset: Offset(0, 5))
          ]),
      child: Column(children: [
        Row(children: [
          for (final label in ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'])
            Expanded(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff94a3b8))))
        ]),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, childAspectRatio: .92),
          itemBuilder: (context, index) {
            final day = index - leading + 1;
            if (day < 1 || day > days) return const SizedBox.shrink();
            final selected = selectedDay.year == month.year &&
                selectedDay.month == month.month &&
                selectedDay.day == day;
            final status = statuses[day];
            final shownStatus =
                status != null && filters.contains(status) ? status : null;
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onSelected(DateTime(month.year, month.month, day)),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: selected ? dashboardBlue : Colors.transparent,
                          shape: BoxShape.circle),
                      child: Text('$day',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  selected ? FontWeight.w800 : FontWeight.w500,
                              color: selected ? Colors.white : dashboardText)),
                    ),
                    const SizedBox(height: 2),
                    if (shownStatus != null)
                      _StatusDot(status: shownStatus, size: 5)
                    else
                      const SizedBox(height: 5),
                  ]),
            );
          },
        ),
        const Divider(height: 28, color: Color(0xfff1f5f9)),
        const Wrap(
            alignment: WrapAlignment.center,
            spacing: 18,
            runSpacing: 8,
            children: [
              _Legend(status: AttendanceStatus.present),
              _Legend(status: AttendanceStatus.late),
              _Legend(status: AttendanceStatus.absent),
            ]),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.status});
  final AttendanceStatus status;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        _StatusDot(status: status, size: 8),
        const SizedBox(width: 6),
        Text(_statusLabel(status),
            style: const TextStyle(fontSize: 12, color: dashboardMuted))
      ]);
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status, this.size = 10});
  final AttendanceStatus status;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration:
          BoxDecoration(color: _statusColor(status), shape: BoxShape.circle));
}

class _RecordCard extends StatelessWidget {
  const _RecordCard(
      {required this.icon,
      required this.iconColor,
      required this.iconBackground,
      required this.title,
      required this.time});
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String time;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xffeef2f7)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x080f172a),
                  blurRadius: 10,
                  offset: Offset(0, 4))
            ]),
        child: Row(children: [
          Container(
              width: 44,
              height: 44,
              decoration:
                  BoxDecoration(color: iconBackground, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 21)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: dashboardText)),
                const SizedBox(height: 5),
                const Row(children: [
                  Icon(Icons.location_on_rounded,
                      size: 14, color: dashboardMuted),
                  SizedBox(width: 3),
                  Text('Main Office HQ',
                      style: TextStyle(fontSize: 12, color: dashboardMuted))
                ])
              ])),
          Text(time,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff334155))),
        ]),
      );
}

class _EmptyRecord extends StatelessWidget {
  const _EmptyRecord({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xffeef2f7))),
      child: Column(children: [
        const Icon(Icons.event_busy_outlined, color: dashboardMuted),
        const SizedBox(height: 8),
        Text(message, style: const TextStyle(color: dashboardMuted))
      ]));
}

Color _statusColor(AttendanceStatus status) => switch (status) {
      AttendanceStatus.present => const Color(0xff10b981),
      AttendanceStatus.late => const Color(0xfff59e0b),
      AttendanceStatus.absent => const Color(0xffef4444),
    };

String _statusLabel(AttendanceStatus status) => switch (status) {
      AttendanceStatus.present => 'Present',
      AttendanceStatus.late => 'Late',
      AttendanceStatus.absent => 'Absent',
    };

String _shortMonth(int month) => const [
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
    ][month - 1];

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

IconData _eventIcon(String kind) => switch (kind) {
      'CLOCK_IN' => Icons.login_rounded,
      'CLOCK_OUT' => Icons.logout_rounded,
      'BREAK_START' => Icons.coffee_rounded,
      'BREAK_END' => Icons.play_arrow_rounded,
      _ => Icons.schedule_rounded,
    };

String _eventTitle(String kind) => switch (kind) {
      'CLOCK_IN' => 'Check In',
      'CLOCK_OUT' => 'Check Out',
      'BREAK_START' => 'Break Start',
      'BREAK_END' => 'Break End',
      _ => kind.replaceAll('_', ' '),
    };

String _time(DateTime value) {
  var hour = value.hour;
  final suffix = hour >= 12 ? 'PM' : 'AM';
  hour %= 12;
  if (hour == 0) hour = 12;
  return '${hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')} $suffix';
}
