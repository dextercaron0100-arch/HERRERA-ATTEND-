import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:geoattend_employee/core/services/app_services.dart';
import 'package:geoattend_employee/core/theme/app_colors.dart';

class ReadinessPage extends ConsumerWidget {
  const ReadinessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(mobileOverviewProvider);
    return Scaffold(
      backgroundColor: dashboardBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Reports & Readiness',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(mobileOverviewProvider),
            child: const Text('Retry'),
          ),
        ),
        data: (data) {
          final accepted =
              data.events.where((event) => event.decision == 'ACCEPTED').length;
          final rejected = data.events.length - accepted;
          final pilot = data.pilot;
          return RefreshIndicator(
            onRefresh: () => ref.refresh(mobileOverviewProvider.future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
              children: [
                const _Heading('Phase 7 · Employee reports',
                    'A reconciled view of records currently stored by the server.'),
                _Panel(children: [
                  _Metric('Attendance days', '${data.summaries.length}',
                      Icons.calendar_month_outlined),
                  _Metric('Accepted clock events', '$accepted',
                      Icons.verified_outlined),
                  _Metric('Rejected clock events', '$rejected',
                      Icons.report_gmailerrorred_outlined),
                  _Metric('Employee requests', '${data.requests.length}',
                      Icons.description_outlined),
                ]),
                const SizedBox(height: 22),
                const _Heading('Phase 8 · Security & release checks',
                    'Core controls required before production rollout.'),
                _Panel(children: [
                  const _Check('Encrypted local session storage', true),
                  const _Check('Server-side GPS decision', true),
                  const _Check('Idempotent offline attendance queue', true),
                  _Check('Registered worksite', data.employee.worksite != null),
                  _Check('Locked payroll payslip',
                      data.payroll?.payslipAvailable == true),
                ]),
                const SizedBox(height: 22),
                const _Heading('Phase 9 · Controlled pilot',
                    'Your enrollment and parallel-payroll reconciliation status.'),
                if (pilot == null)
                  const _EmptyPilot()
                else
                  _PilotCard(
                    name: pilot.name,
                    status: pilot.status,
                    members: pilot.memberCount,
                    completed: pilot.completedCycles,
                    target: pilot.targetCycles,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, this.subtitle);
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: dashboardText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(color: dashboardMuted, height: 1.35)),
        ]),
      );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xffe2e8f0)),
        ),
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const Divider(height: 1, indent: 58),
          ],
        ]),
      );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: dashboardBlue),
        title: Text(label),
        trailing: Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: dashboardText)),
      );
}

class _Check extends StatelessWidget {
  const _Check(this.label, this.passed);
  final String label;
  final bool passed;
  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(
            passed ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: passed ? const Color(0xff16813a) : const Color(0xffa15c00)),
        title: Text(label),
        trailing: Text(passed ? 'Ready' : 'Pending',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: passed
                    ? const Color(0xff16813a)
                    : const Color(0xffa15c00))),
      );
}

class _PilotCard extends StatelessWidget {
  const _PilotCard({
    required this.name,
    required this.status,
    required this.members,
    required this.completed,
    required this.target,
  });
  final String name;
  final String status;
  final int members;
  final int completed;
  final int target;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xff071a38),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.science_outlined, color: Color(0xff9ac7ff)),
            const SizedBox(width: 10),
            Expanded(
                child: Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800))),
            Text(status,
                style: const TextStyle(
                    color: Color(0xff66df75), fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: target == 0 ? 0 : completed / target,
            minHeight: 9,
            borderRadius: BorderRadius.circular(20),
            backgroundColor: const Color(0x33ffffff),
            color: const Color(0xff66df75),
          ),
          const SizedBox(height: 10),
          Text(
              '$completed of $target payroll cycles signed off · $members members',
              style: const TextStyle(color: Color(0xffd7e3f7))),
        ]),
      );
}

class _EmptyPilot extends StatelessWidget {
  const _EmptyPilot();
  @override
  Widget build(BuildContext context) => const _Panel(children: [
        ListTile(
          leading: Icon(Icons.group_add_outlined, color: dashboardMuted),
          title: Text('Not enrolled in an active pilot'),
          subtitle:
              Text('HR will notify you if your branch joins the rollout.'),
        ),
      ]);
}
