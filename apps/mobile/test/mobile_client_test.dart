import 'package:flutter_test/flutter_test.dart';
import 'package:geoattend_employee/data/clients/mobile_client.dart';

void main() {
  test('parses a complete employee overview safely', () {
    final overview = MobileOverview.fromJson({
      'employee': {
        'id': 'employee-1',
        'organizationId': 'organization-1',
        'employeeNumber': 'EMP-001',
        'name': 'Maria Santos',
        'email': 'maria@example.test',
        'role': 'EMPLOYEE',
        'department': 'Operations',
        'worksite': {
          'id': 'worksite-1',
          'name': 'Main Office',
          'latitude': 14.5995,
          'longitude': 120.9842,
          'radiusMeters': 120,
          'maxAccuracyMeters': 40,
        },
      },
      'schedule': {
        'shifts': [
          {
            'dayOfWeek': 1,
            'startMinute': 480,
            'endMinute': 1020,
            'breakMinutes': 60,
            'graceMinutes': 10,
          }
        ],
      },
      'holidays': [
        {
          'date': '2026-08-21T00:00:00.000Z',
          'name': 'Ninoy Aquino Day',
          'category': 'SPECIAL',
        }
      ],
      'attendance': {
        'events': [
          {
            'id': 'event-1',
            'kind': 'CLOCK_IN',
            'capturedAt': '2026-07-20T00:00:00.000Z',
            'decision': 'ACCEPTED',
            'reasonCodes': <String>[],
            'distanceMeters': 8.5,
          }
        ],
        'summaries': <Map<String, Object?>>[],
      },
      'requests': <Map<String, Object?>>[],
      'notifications': <Map<String, Object?>>[],
      'leaveBalances': {'vacation': 12, 'sick': 5, 'personal': 3},
      'payroll': {
        'id': 'run-1',
        'periodStart': '2026-07-01T00:00:00.000Z',
        'periodEnd': '2026-07-15T00:00:00.000Z',
        'status': 'LOCKED',
        'currency': 'PHP',
        'payslipAvailable': true,
        'lines': [
          {
            'code': 'BASE',
            'description': 'Basic Salary',
            'category': 'EARNING',
            'amount': '15000.00',
          }
        ],
      },
      'pilot': {
        'id': 'pilot-1',
        'name': 'Main Office Pilot',
        'status': 'ACTIVE',
        'enrolledAt': '2026-07-01T00:00:00.000Z',
        'targetCycles': 2,
        'completedCycles': 1,
        'memberCount': 12,
      },
    });

    expect(overview.employee.employeeNumber, 'EMP-001');
    expect(overview.employee.worksite?.radiusMeters, 120);
    expect(overview.shifts.single.startMinute, 480);
    expect(overview.holidays.single.name, 'Ninoy Aquino Day');
    expect(overview.events.single.distanceMeters, 8.5);
    expect(overview.leaveBalances['vacation'], 12);
    expect(overview.payroll?.currency, 'PHP');
    expect(overview.payroll?.lines.single.amount, 15000);
    expect(overview.payroll?.payslipAvailable, isTrue);
    expect(overview.pilot?.completedCycles, 1);
  });

  test('handles optional payroll and pilot data', () {
    final overview = MobileOverview.fromJson({
      'employee': {
        'id': 'employee-1',
        'organizationId': 'organization-1',
        'employeeNumber': 'EMP-001',
        'name': 'Maria Santos',
        'email': 'maria@example.test',
        'role': 'EMPLOYEE',
      },
      'schedule': null,
      'holidays': <Object>[],
      'attendance': null,
      'requests': <Object>[],
      'notifications': <Object>[],
      'leaveBalances': <String, int>{},
      'payroll': null,
      'pilot': null,
    });

    expect(overview.shifts, isEmpty);
    expect(overview.events, isEmpty);
    expect(overview.payroll, isNull);
    expect(overview.pilot, isNull);
  });
}
