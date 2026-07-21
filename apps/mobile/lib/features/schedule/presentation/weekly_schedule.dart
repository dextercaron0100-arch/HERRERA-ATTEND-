import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:geoattend_employee/core/services/app_services.dart';
import 'package:geoattend_employee/core/theme/app_colors.dart';
import 'package:geoattend_employee/data/clients/mobile_client.dart';

class WeeklySchedulePage extends ConsumerStatefulWidget {
  const WeeklySchedulePage({super.key});

  @override
  ConsumerState<WeeklySchedulePage> createState() => _WeeklySchedulePageState();
}

class _WeeklySchedulePageState extends ConsumerState<WeeklySchedulePage>
    with SingleTickerProviderStateMixin {
  late DateTime weekStart;
  late DateTime selectedDay;
  late AnimationController entrance;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    selectedDay = DateTime(now.year, now.month, now.day);
    entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850))
      ..forward();
  }

  @override
  void dispose() {
    entrance.dispose();
    super.dispose();
  }

  void changeWeek(int offset) {
    setState(() {
      weekStart = weekStart.add(Duration(days: offset * 7));
      selectedDay = weekStart;
    });
    entrance.forward(from: 0);
  }

  String get weekLabel {
    final end = weekStart.add(const Duration(days: 6));
    if (weekStart.month == end.month) {
      return '${_month(weekStart.month)} ${weekStart.day} – ${end.day}, ${end.year}';
    }
    return '${_month(weekStart.month)} ${weekStart.day} – ${_month(end.month)} ${end.day}, ${end.year}';
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(mobileOverviewProvider).asData?.value;
    return Scaffold(
      backgroundColor: const Color(0xfff6faff),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        shadowColor: const Color(0x140f172a),
        title: const Text('Work Schedule',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () => context.push('/schedule/month'),
              tooltip: 'Monthly view',
              icon: const Icon(Icons.calendar_month_outlined)),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
                onPressed: () => context.push('/requests/new'),
                icon: const Icon(Icons.notifications_none_rounded)),
          ),
        ],
      ),
      body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        final side = constraints.maxWidth >= 700 ? 48.0 : 16.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(side, 18, side, 30),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(weekLabel,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: dashboardText))),
                      _RoundButton(
                          icon: Icons.chevron_left_rounded,
                          onPressed: () => changeWeek(-1)),
                      const SizedBox(width: 7),
                      _RoundButton(
                          icon: Icons.chevron_right_rounded,
                          onPressed: () => changeWeek(1)),
                    ]),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 7,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final day = weekStart.add(Duration(days: index));
                          return _StaggeredEntrance(
                            controller: entrance,
                            index: index,
                            child: _DayButton(
                              day: day,
                              selected: _sameDay(day, selectedDay),
                              today: _sameDay(day, DateTime.now()),
                              rest: day.weekday >= 6,
                              onTap: () => setState(() => selectedDay = day),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 22),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                            position: Tween(
                                    begin: const Offset(.04, .04),
                                    end: Offset.zero)
                                .animate(animation),
                            child: child),
                      ),
                      child: _ScheduleForDay(
                          key: ValueKey(selectedDay),
                          day: selectedDay,
                          shifts: overview?.shifts ?? const [],
                          location: overview?.employee.worksite?.name ??
                              'Main Office'),
                    ),
                    const SizedBox(height: 18),
                    _StaggeredEntrance(
                      controller: entrance,
                      index: 5,
                      child:
                          _WeekOverview(shifts: overview?.shifts ?? const []),
                    ),
                  ]),
            ),
          ),
        );
      })),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xffecf5fe),
        shape: const CircleBorder(),
        child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(icon, size: 22, color: dashboardBlue))),
      );
}

class _DayButton extends StatelessWidget {
  const _DayButton(
      {required this.day,
      required this.selected,
      required this.today,
      required this.rest,
      required this.onTap});
  final DateTime day;
  final bool selected;
  final bool today;
  final bool rest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        button: true,
        label: '${_weekday(day.weekday)} ${day.day}',
        child: AnimatedScale(
          duration: const Duration(milliseconds: 220),
          scale: selected ? 1.04 : 1,
          curve: Curves.easeOutBack,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(17),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 68,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xff071a38)
                    : rest
                        ? const Color(0xffe0e9f2)
                        : Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                    color: selected
                        ? const Color(0xff071a38)
                        : const Color(0xffd7dfe7)),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                            color: Color(0x30071a38),
                            blurRadius: 14,
                            offset: Offset(0, 6))
                      ]
                    : null,
              ),
              child: Stack(alignment: Alignment.center, children: [
                if (today)
                  Positioned(
                      top: 5,
                      child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                              color: Color(0xff66df75),
                              shape: BoxShape.circle))),
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_weekday(day.weekday).substring(0, 3).toUpperCase(),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .5,
                          color: selected
                              ? const Color(0xffd8e2ff)
                              : dashboardMuted)),
                  const SizedBox(height: 5),
                  Text('${day.day}',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: selected ? Colors.white : dashboardText)),
                ]),
              ]),
            ),
          ),
        ),
      );
}

class _ScheduleForDay extends StatelessWidget {
  const _ScheduleForDay(
      {super.key,
      required this.day,
      required this.shifts,
      required this.location});
  final DateTime day;
  final List<WorkShift> shifts;
  final String location;

  @override
  Widget build(BuildContext context) {
    WorkShift? shift;
    for (final item in shifts) {
      if (item.dayOfWeek == day.weekday) shift = item;
    }
    if (shift == null) return _RestCard(day: day);
    return _ShiftCard(
        day: day,
        shift: shift,
        location: location,
        current: _sameDay(day, DateTime.now()));
  }
}

class _ShiftCard extends StatefulWidget {
  const _ShiftCard(
      {required this.day,
      required this.shift,
      required this.location,
      required this.current});
  final DateTime day;
  final WorkShift shift;
  final String location;
  final bool current;
  @override
  State<_ShiftCard> createState() => _ShiftCardState();
}

class _ShiftCardState extends State<_ShiftCard> {
  bool expanded = true;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xff16813a);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      padding: const EdgeInsets.fromLTRB(19, 18, 16, 16),
      decoration: BoxDecoration(
          color: const Color(0xfff1fbf3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: .23)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0a0f172a), blurRadius: 13, offset: Offset(0, 5))
          ]),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                  color: accent, borderRadius: BorderRadius.circular(5))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                          '${_weekday(widget.day.weekday)}, ${_month(widget.day.month)} ${widget.day.day}',
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: dashboardText)),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: accent.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Text('On-site',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: accent))),
                    ]),
                const SizedBox(height: 4),
                const Text('Assigned Shift',
                    style: TextStyle(fontSize: 13, color: dashboardMuted)),
              ])),
          IconButton(
              onPressed: () => setState(() => expanded = !expanded),
              icon: AnimatedRotation(
                  turns: expanded ? .5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(Icons.expand_more_rounded))),
        ]),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: expanded
              ? Column(children: [
                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(
                        child: _ShiftDetail(
                            icon: Icons.schedule_rounded,
                            label: 'TIME',
                            value:
                                '${_minuteTime(widget.shift.startMinute)} – ${_minuteTime(widget.shift.endMinute)}')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _ShiftDetail(
                            icon: Icons.pin_drop_rounded,
                            label: 'LOCATION',
                            value: widget.location)),
                  ]),
                  if (widget.current) ...[
                    const SizedBox(height: 18),
                    FilledButton.icon(
                        onPressed: () => context.pop(),
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Check In')),
                  ],
                ])
              : const SizedBox.shrink(),
        ),
      ]),
    );
  }
}

class _ShiftDetail extends StatelessWidget {
  const _ShiftDetail(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: dashboardMuted),
        const SizedBox(width: 7),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .6,
                  color: dashboardMuted)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: dashboardText))
        ]))
      ]);
}

class _RestCard extends StatelessWidget {
  const _RestCard({required this.day});
  final DateTime day;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18),
        decoration: BoxDecoration(
            color: const Color(0xffe7eef5),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: dashboardMuted, style: BorderStyle.solid)),
        child: Column(children: [
          const Icon(Icons.weekend_rounded, size: 34, color: dashboardMuted),
          const SizedBox(height: 9),
          Text('${_weekday(day.weekday)}, ${_month(day.month)} ${day.day}',
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff44474e))),
          const SizedBox(height: 4),
          const Text('Scheduled Rest Day',
              style: TextStyle(fontSize: 13, color: dashboardMuted))
        ]),
      );
}

class _WeekOverview extends StatelessWidget {
  const _WeekOverview({required this.shifts});
  final List<WorkShift> shifts;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xffe0e7ee))),
        child: Row(children: [
          Expanded(
              child: _OverviewItem(
                  value:
                      '${(shifts.fold<int>(0, (sum, item) => sum + item.endMinute - item.startMinute - item.breakMinutes) / 60).toStringAsFixed(0)}h',
                  label: 'Scheduled')),
          const SizedBox(height: 38, child: VerticalDivider()),
          Expanded(
              child:
                  _OverviewItem(value: '${shifts.length}', label: 'On-site')),
          const SizedBox(height: 38, child: VerticalDivider()),
          const Expanded(child: _OverviewItem(value: '0', label: 'Remote')),
        ]),
      );
}

class _OverviewItem extends StatelessWidget {
  const _OverviewItem({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: dashboardBlue)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: dashboardMuted))
      ]);
}

class _StaggeredEntrance extends StatelessWidget {
  const _StaggeredEntrance(
      {required this.controller, required this.index, required this.child});
  final AnimationController controller;
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final start = (index * .07).clamp(0.0, .65);
    final animation = CurvedAnimation(
        parent: controller,
        curve: Interval(start, (start + .35).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic));
    return FadeTransition(
        opacity: animation,
        child: SlideTransition(
            position: Tween(begin: const Offset(0, .14), end: Offset.zero)
                .animate(animation),
            child: child));
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
String _weekday(int value) => const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ][value - 1];
String _month(int value) => const [
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
    ][value - 1];

String _minuteTime(int minute) {
  final hour = minute ~/ 60;
  final min = minute % 60;
  return '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
}
