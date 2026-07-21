import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'package:geoattend_employee/core/services/app_services.dart';
import 'package:geoattend_employee/core/theme/app_colors.dart';
import 'package:geoattend_employee/data/clients/mobile_client.dart';

const _payrollNavy = Color(0xff071a38);
const _payrollGreen = Color(0xff66df75);
const _payrollRed = Color(0xffba1a1a);

class PayrollDashboardPage extends ConsumerWidget {
  const PayrollDashboardPage({super.key});

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature will be available in the next phase.')),
    );
  }

  Future<void> _openPayslip(
      BuildContext context, WidgetRef ref, PayrollInfo? payroll) async {
    final runId = payroll?.id;
    final employeeId = ref.read(authControllerProvider).employeeId;
    if (runId == null ||
        employeeId == null ||
        payroll?.payslipAvailable != true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('A payslip is available after payroll is locked.')));
      return;
    }
    try {
      final bytes =
          await ref.read(mobileClientProvider).payslip(employeeId, runId);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/herrera-payslip-$runId.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFilex.open(file.path, type: 'application/pdf');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('The payslip could not be opened. Try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mobileOverviewProvider);
    final payroll = state.asData?.value.payroll;
    final earnings =
        payroll?.lines.where((line) => line.category == 'EARNING').toList() ??
            const [];
    final deductions =
        payroll?.lines.where((line) => line.category == 'DEDUCTION').toList() ??
            const [];
    final gross = earnings.fold<double>(0, (sum, line) => sum + line.amount);
    final deductionTotal =
        deductions.fold<double>(0, (sum, line) => sum + line.amount);
    final net = gross - deductionTotal;
    return Scaffold(
      backgroundColor: const Color(0xfff6faff),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        shadowColor: const Color(0x140f172a),
        title: const Text('Payroll',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Badge(
              smallSize: 8,
              backgroundColor: _payrollRed,
              child: IconButton(
                onPressed: () => context.push('/requests/new'),
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 780;
          final side = wide ? 32.0 : 16.0;
          final summary =
              _CurrentPeriodCard(wide: wide, payroll: payroll, net: net);
          final details = Column(children: [
            _MoneySection(
              title: 'Earnings',
              icon: Icons.arrow_upward_rounded,
              rows: earnings.isEmpty
                  ? const [_MoneyRow('No calculated earnings', '₱0.00')]
                  : earnings
                      .map((line) =>
                          _MoneyRow(line.description, _peso(line.amount)))
                      .toList(),
              totalLabel: 'TOTAL EARNINGS',
              total: _peso(gross),
            ),
            const SizedBox(height: 16),
            _MoneySection(
              title: 'Deductions',
              icon: Icons.arrow_downward_rounded,
              deduction: true,
              rows: deductions.isEmpty
                  ? const [_MoneyRow('No deductions', '−₱0.00')]
                  : deductions
                      .map((line) =>
                          _MoneyRow(line.description, '−${_peso(line.amount)}'))
                      .toList(),
              totalLabel: 'TOTAL DEDUCTIONS',
              total: '−${_peso(deductionTotal)}',
            ),
          ]);
          final actions = _QuickActions(onTap: (name) {
            if (name == 'View Payslips') {
              _openPayslip(context, ref, payroll);
            } else {
              _comingSoon(context, name);
            }
          });

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(side, 20, side, 30),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(children: [
                  if (wide)
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              flex: 2,
                              child: Column(children: [
                                summary,
                                const SizedBox(height: 16),
                                details
                              ])),
                          const SizedBox(width: 20),
                          Expanded(child: actions),
                        ])
                  else ...[
                    summary,
                    const SizedBox(height: 16),
                    details,
                    const SizedBox(height: 16),
                    actions,
                  ],
                  const SizedBox(height: 16),
                  _NetPayCard(
                      gross: gross, deductions: deductionTotal, net: net),
                  const SizedBox(height: 10),
                  const Text(
                    '*Estimated salary may change before final payroll approval.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: dashboardMuted),
                  ),
                ]),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CurrentPeriodCard extends StatelessWidget {
  const _CurrentPeriodCard(
      {required this.wide, required this.payroll, required this.net});
  final bool wide;
  final PayrollInfo? payroll;
  final double net;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(wide ? 24 : 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_payrollNavy, Color(0xff1a2b4b)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33031a35), blurRadius: 22, offset: Offset(0, 10))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _CardLabel('CURRENT PERIOD'),
                  SizedBox(height: 5),
                  Text(_periodLabel(payroll),
                      style: const TextStyle(
                          color: Color(0xd9ffffff), fontSize: 14)),
                ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                  color: const Color(0x24ffffff),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x33ffffff))),
              child: Text(payroll?.status ?? 'Not Available',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 26),
          const _CardLabel('ESTIMATED NET SALARY'),
          const SizedBox(height: 6),
          Text(_peso(net),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.8)),
          const SizedBox(height: 26),
          const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CardLabel('CYCLE PROGRESS'),
                Text('20 / 31 Days',
                    style: TextStyle(
                        color: Color(0xffd8e2ff),
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ]),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
                value: 20 / 31,
                minHeight: 8,
                backgroundColor: Color(0x33ffffff),
                valueColor: AlwaysStoppedAnimation(_payrollGreen)),
          ),
        ]),
      );
}

class _CardLabel extends StatelessWidget {
  const _CardLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: Color(0xffd8e2ff),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: .8));
}

class _MoneyRow {
  const _MoneyRow(this.label, this.amount);
  final String label;
  final String amount;
}

class _MoneySection extends StatelessWidget {
  const _MoneySection(
      {required this.title,
      required this.icon,
      required this.rows,
      required this.totalLabel,
      required this.total,
      this.deduction = false});
  final String title;
  final IconData icon;
  final List<_MoneyRow> rows;
  final String totalLabel;
  final String total;
  final bool deduction;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffe3e8ef)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x080f172a),
                  blurRadius: 12,
                  offset: Offset(0, 5))
            ]),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 9),
            child: Row(children: [
              Icon(icon,
                  size: 22, color: deduction ? _payrollRed : _payrollNavy),
              const SizedBox(width: 9),
              Text(title,
                  style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: dashboardText))
            ]),
          ),
          const Divider(height: 1, color: Color(0xffedf1f5)),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(children: [
                Expanded(
                    child: Text(row.label,
                        style: const TextStyle(
                            fontSize: 14, color: dashboardMuted))),
                Text(row.amount,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: deduction ? _payrollRed : _payrollNavy))
              ]),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: BoxDecoration(
                color: deduction
                    ? const Color(0xfffff4f2)
                    : const Color(0xfff0f6fc),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(19))),
            child: Row(children: [
              Expanded(
                  child: Text(totalLabel,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .6,
                          color: dashboardMuted))),
              Text(total,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: deduction ? _payrollRed : _payrollNavy))
            ]),
          ),
        ]),
      );
}

class _NetPayCard extends StatelessWidget {
  const _NetPayCard(
      {required this.gross, required this.deductions, required this.net});
  final double gross;
  final double deductions;
  final double net;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xffdbe4ed))),
        child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runAlignment: WrapAlignment.center,
            spacing: 30,
            runSpacing: 14,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('CALCULATION',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .6,
                        color: dashboardMuted)),
                const SizedBox(height: 5),
                Text('${_peso(gross)}  −  ${_peso(deductions)}',
                    style:
                        const TextStyle(fontSize: 14, color: Color(0xff5c5f60)))
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('ESTIMATED NET PAY',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .6,
                        color: _payrollNavy)),
                const SizedBox(height: 4),
                Text(_peso(net),
                    style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: _payrollNavy))
              ]),
            ]),
      );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onTap});
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffe3e8ef))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Quick Actions',
              style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: _payrollNavy)),
          const SizedBox(height: 12),
          _ActionTile(
              icon: Icons.request_quote_outlined,
              label: 'View Payslips',
              onTap: onTap),
          _ActionTile(
              icon: Icons.account_balance_outlined,
              label: 'Tax Information',
              onTap: onTap),
          _ActionTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Bank Details',
              onTap: onTap),
        ]),
      );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Material(
          color: const Color(0xfff8fbff),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => onTap(label),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xffe3e8ef)),
                  borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        color: Color(0xffe8eef8), shape: BoxShape.circle),
                    child: Icon(icon, color: _payrollNavy, size: 21)),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: dashboardText))),
                const Icon(Icons.chevron_right_rounded, color: dashboardMuted)
              ]),
            ),
          ),
        ),
      );
}

String _peso(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts.first;
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return '₱$buffer.${parts.last}';
}

String _shortDate(DateTime value) {
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
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}

String _periodLabel(PayrollInfo? payroll) {
  final start = payroll?.periodStart;
  final end = payroll?.periodEnd;
  if (start == null) return 'No active payroll period';
  return '${_shortDate(start)} – ${end == null ? 'Current' : _shortDate(end)}';
}
