import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geoattend_employee/core/services/app_services.dart';

class RequestPage extends ConsumerStatefulWidget {
  const RequestPage({super.key});
  @override
  ConsumerState<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends ConsumerState<RequestPage> {
  final reason = TextEditingController();
  final originalEventId = TextEditingController();
  String type = 'LEAVE';
  String correctedKind = 'CLOCK_OUT';
  bool submitting = false;
  String? message;
  DateTime requestStart = DateTime.now();
  DateTime requestEnd = DateTime.now().add(const Duration(hours: 8));
  @override
  void dispose() {
    reason.dispose();
    originalEventId.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (reason.text.trim().length < 3) {
      setState(() => message = 'Please enter a reason.');
      return;
    }
    if (type == 'ATTENDANCE_CORRECTION' &&
        originalEventId.text.trim().isEmpty) {
      setState(() => message = 'Enter the original attendance event ID.');
      return;
    }
    setState(() => submitting = true);
    try {
      final id = await ref.read(requestClientProvider).submit(
          type: type,
          startsAt: requestStart,
          endsAt: requestEnd,
          reason: reason.text.trim(),
          evidence: type == 'ATTENDANCE_CORRECTION'
              ? {
                  'originalEventId': originalEventId.text.trim(),
                  'correctedKind': correctedKind
                }
              : {});
      if (mounted) {
        ref.invalidate(mobileOverviewProvider);
        setState(
            () => message = 'Submitted for approval (${id.substring(0, 8)}).');
      }
    } catch (error) {
      if (mounted) {
        setState(() => message = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  Future<void> pickDates() async {
    final today = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 2),
      initialDateRange: DateTimeRange(
        start:
            DateTime(requestStart.year, requestStart.month, requestStart.day),
        end: DateTime(requestEnd.year, requestEnd.month, requestEnd.day),
      ),
    );
    if (range == null) return;
    setState(() {
      requestStart =
          DateTime(range.start.year, range.start.month, range.start.day, 8);
      requestEnd = DateTime(range.end.year, range.end.month, range.end.day, 17);
      if (!requestEnd.isAfter(requestStart)) {
        requestEnd = requestStart.add(const Duration(hours: 8));
      }
    });
  }

  String formatDate(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          backgroundColor: const Color(0xff031635),
          foregroundColor: Colors.white,
          title: const Text('New request',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                              color: const Color(0xffecf5fe),
                              borderRadius: BorderRadius.circular(18)),
                          child: const Row(children: [
                            Icon(Icons.assignment_outlined,
                                color: Color(0xff031635)),
                            SizedBox(width: 13),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('Send for approval',
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800)),
                                  SizedBox(height: 4),
                                  Text(
                                      'Your supervisor and HR will receive this request.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xff5c5f60)))
                                ]))
                          ])),
                      const SizedBox(height: 22),
                      DropdownButtonFormField<String>(
                          initialValue: type,
                          decoration: const InputDecoration(
                              labelText: 'Request type',
                              prefixIcon: Icon(Icons.category_outlined)),
                          items: const [
                            ('LEAVE', 'Leave'),
                            ('OVERTIME', 'Overtime'),
                            ('REMOTE_WORK', 'Remote work'),
                            ('FIELD_ASSIGNMENT', 'Field assignment'),
                            ('ATTENDANCE_CORRECTION', 'Attendance correction')
                          ]
                              .map((item) => DropdownMenuItem(
                                  value: item.$1, child: Text(item.$2)))
                              .toList(),
                          onChanged: (value) => setState(() => type = value!)),
                      const SizedBox(height: 18),
                      InkWell(
                        onTap: pickDates,
                        borderRadius: BorderRadius.circular(14),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                              labelText: 'Request dates',
                              prefixIcon: Icon(Icons.date_range_rounded),
                              suffixIcon: Icon(Icons.edit_calendar_outlined)),
                          child: Text(
                            '${formatDate(requestStart)} – ${formatDate(requestEnd)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (type == 'ATTENDANCE_CORRECTION') ...[
                        TextField(
                            controller: originalEventId,
                            decoration: const InputDecoration(
                                labelText: 'Original event ID',
                                prefixIcon: Icon(Icons.tag_rounded))),
                        const SizedBox(height: 18),
                        DropdownButtonFormField<String>(
                            initialValue: correctedKind,
                            decoration: const InputDecoration(
                                labelText: 'Correct event',
                                border: OutlineInputBorder()),
                            items: const [
                              'CLOCK_IN',
                              'BREAK_START',
                              'BREAK_END',
                              'CLOCK_OUT'
                            ]
                                .map((value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value.replaceAll('_', ' '))))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => correctedKind = value!)),
                        const SizedBox(height: 18),
                      ],
                      TextField(
                          controller: reason,
                          maxLines: 5,
                          decoration: const InputDecoration(
                              labelText: 'Reason',
                              hintText: 'Add the details your approver needs',
                              alignLabelWithHint: true)),
                      const SizedBox(height: 18),
                      FilledButton(
                          onPressed: submitting ? null : submit,
                          child: Text(
                              submitting ? 'Submitting...' : 'SUBMIT REQUEST')),
                      if (message != null)
                        Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                                color: const Color(0xffecf5fe),
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(message!, textAlign: TextAlign.center))
                    ])))
      ]));
}
