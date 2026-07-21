import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:geoattend_employee/core/services/app_services.dart';
import 'package:geoattend_employee/core/theme/app_colors.dart';
import 'package:geoattend_employee/data/clients/mobile_client.dart';

enum _ScheduleKind { normal, rest, holiday }

class MonthlySchedulePage extends ConsumerStatefulWidget {
  const MonthlySchedulePage({super.key});

  @override
  ConsumerState<MonthlySchedulePage> createState() =>
      _MonthlySchedulePageState();
}

class _MonthlySchedulePageState extends ConsumerState<MonthlySchedulePage>
    with SingleTickerProviderStateMixin {
  late DateTime month;
  late DateTime selectedDay;
  late AnimationController entrance;
  List<WorkShift> shifts = const [];
  List<HolidayInfo> holidays = const [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    month = DateTime(now.year, now.month);
    selectedDay = DateTime(now.year, now.month, now.day);
    entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
  }

  @override
  void dispose() {
    entrance.dispose();
    super.dispose();
  }

  void changeMonth(int offset) {
    setState(() {
      month = DateTime(month.year, month.month + offset);
      selectedDay = DateTime(month.year, month.month, 1);
    });
    entrance.forward(from: 0);
  }

  _ScheduleKind kindFor(DateTime day) {
    if (holidays.any((item) => _sameDay(item.date, day))) {
      return _ScheduleKind.holiday;
    }
    if (shifts.any((item) => item.dayOfWeek == day.weekday)) {
      return _ScheduleKind.normal;
    }
    return _ScheduleKind.rest;
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(mobileOverviewProvider).asData?.value;
    shifts = overview?.shifts ?? const [];
    holidays = overview?.holidays ?? const [];
    return Scaffold(
      backgroundColor: const Color(0xfff6faff),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        shadowColor: const Color(0x140f172a),
        title: const Text('Monthly Schedule',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () => context.pop(),
              tooltip: 'Weekly view',
              icon: const Icon(Icons.view_week_outlined)),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        final side = constraints.maxWidth >= 700 ? 48.0 : 16.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(side, 18, side, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeTransition(
                      opacity: CurvedAnimation(
                          parent: entrance,
                          curve: const Interval(0, .45, curve: Curves.easeOut)),
                      child: _CalendarCard(
                        month: month,
                        selectedDay: selectedDay,
                        entrance: entrance,
                        kindFor: kindFor,
                        onPrevious: () => changeMonth(-1),
                        onNext: () => changeMonth(1),
                        onSelected: (day) => setState(() => selectedDay = day),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 340),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                            position: Tween(
                                    begin: const Offset(0, .08),
                                    end: Offset.zero)
                                .animate(animation),
                            child: child),
                      ),
                      child: _SelectedDayDetails(
                          key: ValueKey(selectedDay),
                          day: selectedDay,
                          kind: kindFor(selectedDay)),
                    ),
                  ]),
            ),
          ),
        );
      })),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard(
      {required this.month,
      required this.selectedDay,
      required this.entrance,
      required this.kindFor,
      required this.onPrevious,
      required this.onNext,
      required this.onSelected});
  final DateTime month;
  final DateTime selectedDay;
  final AnimationController entrance;
  final _ScheduleKind Function(DateTime) kindFor;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final days = DateTime(month.year, month.month + 1, 0).day;
    final leading = DateTime(month.year, month.month, 1).weekday % 7;
    final count = ((leading + days + 6) ~/ 7) * 7;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xffdfe6ec)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0a0f172a), blurRadius: 14, offset: Offset(0, 6))
          ]),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: const Color(0xffecf5fe),
          child: Row(children: [
            IconButton(
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded)),
            Expanded(
                child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text('${_monthName(month.month)} ${month.year}',
                        key: ValueKey(month),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff031635))))),
            IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
          child: Column(children: [
            Row(children: [
              for (final label in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                Expanded(
                    child: Text(label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: dashboardMuted)))
            ]),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: count,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, childAspectRatio: .9),
              itemBuilder: (context, index) {
                final value = index - leading + 1;
                if (value < 1 || value > days) return const SizedBox.shrink();
                final day = DateTime(month.year, month.month, value);
                final start = (.04 + index * .012).clamp(0.0, .72);
                final animation = CurvedAnimation(
                    parent: entrance,
                    curve: Interval(start, (start + .26).clamp(0.0, 1.0),
                        curve: Curves.easeOutCubic));
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position:
                        Tween(begin: const Offset(0, .18), end: Offset.zero)
                            .animate(animation),
                    child: _CalendarDay(
                        day: day,
                        kind: kindFor(day),
                        selected: _sameDay(day, selectedDay),
                        today: _sameDay(day, DateTime.now()),
                        onTap: () => onSelected(day)),
                  ),
                );
              },
            ),
          ]),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          decoration: const BoxDecoration(
              color: Color(0xffe6eff8),
              border: Border(top: BorderSide(color: Color(0xffd6dfe7)))),
          child: const Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 8,
              children: [
                _Legend(kind: _ScheduleKind.normal, label: 'Normal'),
                _Legend(kind: _ScheduleKind.rest, label: 'Rest Day'),
                _Legend(kind: _ScheduleKind.holiday, label: 'Holiday'),
              ]),
        ),
      ]),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay(
      {required this.day,
      required this.kind,
      required this.selected,
      required this.today,
      required this.onTap});
  final DateTime day;
  final _ScheduleKind kind;
  final bool selected;
  final bool today;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedScale(
          scale: selected ? 1.08 : 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 230),
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
                color: selected ? const Color(0xff1a2b4b) : Colors.transparent,
                borderRadius: BorderRadius.circular(13),
                border: today && !selected
                    ? Border.all(color: dashboardBlue)
                    : null),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${day.day}',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? Colors.white : dashboardText)),
              const SizedBox(height: 5),
              Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color:
                          selected ? const Color(0xff8293b8) : _kindColor(kind),
                      shape: BoxShape.circle)),
            ]),
          ),
        ),
      );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.kind, required this.label});
  final _ScheduleKind kind;
  final String label;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 9,
            height: 9,
            decoration:
                BoxDecoration(color: _kindColor(kind), shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: dashboardMuted))
      ]);
}

class _SelectedDayDetails extends StatelessWidget {
  const _SelectedDayDetails({super.key, required this.day, required this.kind});
  final DateTime day;
  final _ScheduleKind kind;
  @override
  Widget build(BuildContext context) {
    final rest = kind == _ScheduleKind.rest;
    final holiday = kind == _ScheduleKind.holiday;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${_weekday(day.weekday)}, ${_monthName(day.month)} ${day.day}',
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xff031635))),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffdfe6ec)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x090f172a),
                  blurRadius: 12,
                  offset: Offset(0, 5))
            ]),
        child: rest || holiday
            ? Column(children: [
                Icon(
                    holiday ? Icons.celebration_rounded : Icons.weekend_rounded,
                    size: 34,
                    color: _kindColor(kind)),
                const SizedBox(height: 9),
                Text(holiday ? 'Company Holiday' : 'Scheduled Rest Day',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: dashboardText))
              ])
            : Row(children: [
                Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                        color: Color(0xffd8e2ff), shape: BoxShape.circle),
                    child: const Icon(Icons.schedule_rounded,
                        color: Color(0xff031635), size: 26)),
                const SizedBox(width: 14),
                const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('09:00 – 18:00',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: dashboardText)),
                      SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.location_on_rounded,
                            size: 16, color: dashboardMuted),
                        SizedBox(width: 4),
                        Text('Main Office HQ',
                            style:
                                TextStyle(fontSize: 12, color: dashboardMuted))
                      ])
                    ])),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                        color: const Color(0xffe6eff8),
                        borderRadius: BorderRadius.circular(15)),
                    child: const Text('REGULAR',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: dashboardMuted))),
              ]),
      ),
    ]);
  }
}

Color _kindColor(_ScheduleKind kind) => switch (kind) {
      _ScheduleKind.normal => const Color(0xff1d4e89),
      _ScheduleKind.rest => const Color(0xff75777f),
      _ScheduleKind.holiday => const Color(0xff16813a),
    };
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
String _monthName(int value) => const [
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
    ][value - 1];
