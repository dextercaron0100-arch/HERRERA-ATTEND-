import 'package:dio/dio.dart';

class MobileClient {
  const MobileClient(this._dio);
  final Dio _dio;

  Future<MobileOverview> overview(String employeeId) async {
    final response = await _dio
        .get<Map<String, dynamic>>('/mobile/employees/$employeeId/overview');
    if (response.data == null) throw StateError('Employee data was empty');
    return MobileOverview.fromJson(response.data!);
  }

  Future<List<EmployeeRequest>> requests(String employeeId) async {
    final response = await _dio.get<List<dynamic>>('/requests',
        queryParameters: {'employeeId': employeeId});
    return (response.data ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(EmployeeRequest.fromJson)
        .toList();
  }

  Future<List<int>> payslip(String employeeId, String runId) async {
    final response = await _dio.get<List<int>>(
      '/mobile/employees/$employeeId/payslip',
      queryParameters: {'runId': runId},
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? const [];
  }
}

class MobileOverview {
  const MobileOverview(
      {required this.employee,
      required this.shifts,
      required this.holidays,
      required this.events,
      required this.summaries,
      required this.requests,
      required this.notifications,
      required this.leaveBalances,
      this.pilot,
      this.payroll});

  factory MobileOverview.fromJson(Map<String, dynamic> json) {
    final attendance = _map(json['attendance']);
    final schedule = _map(json['schedule']);
    return MobileOverview(
      employee: EmployeeProfile.fromJson(_map(json['employee'])),
      shifts: _list(schedule['shifts']).map(WorkShift.fromJson).toList(),
      holidays: _list(json['holidays']).map(HolidayInfo.fromJson).toList(),
      events: _list(attendance['events'])
          .map(AttendanceEventInfo.fromJson)
          .toList(),
      summaries: _list(attendance['summaries'])
          .map(AttendanceSummaryInfo.fromJson)
          .toList(),
      requests: _list(json['requests']).map(EmployeeRequest.fromJson).toList(),
      notifications: _list(json['notifications'])
          .map(EmployeeNotification.fromJson)
          .toList(),
      leaveBalances: Map<String, int>.from(_map(json['leaveBalances'])
          .map((key, value) => MapEntry(key, (value as num).toInt()))),
      pilot: json['pilot'] == null
          ? null
          : PilotInfo.fromJson(_map(json['pilot'])),
      payroll: json['payroll'] == null
          ? null
          : PayrollInfo.fromJson(_map(json['payroll'])),
    );
  }

  final EmployeeProfile employee;
  final List<WorkShift> shifts;
  final List<HolidayInfo> holidays;
  final List<AttendanceEventInfo> events;
  final List<AttendanceSummaryInfo> summaries;
  final List<EmployeeRequest> requests;
  final List<EmployeeNotification> notifications;
  final Map<String, int> leaveBalances;
  final PilotInfo? pilot;
  final PayrollInfo? payroll;
}

class PilotInfo {
  const PilotInfo({
    required this.id,
    required this.name,
    required this.status,
    required this.enrolledAt,
    required this.targetCycles,
    required this.completedCycles,
    required this.memberCount,
  });
  factory PilotInfo.fromJson(Map<String, dynamic> json) => PilotInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        status: json['status'] as String,
        enrolledAt: DateTime.parse(json['enrolledAt'] as String).toLocal(),
        targetCycles: (json['targetCycles'] as num).toInt(),
        completedCycles: (json['completedCycles'] as num).toInt(),
        memberCount: (json['memberCount'] as num).toInt(),
      );
  final String id;
  final String name;
  final String status;
  final DateTime enrolledAt;
  final int targetCycles;
  final int completedCycles;
  final int memberCount;
}

class EmployeeProfile {
  const EmployeeProfile(
      {required this.id,
      required this.organizationId,
      required this.employeeNumber,
      required this.name,
      required this.email,
      required this.role,
      this.department,
      this.worksite});
  factory EmployeeProfile.fromJson(Map<String, dynamic> json) =>
      EmployeeProfile(
          id: json['id'] as String,
          organizationId: json['organizationId'] as String,
          employeeNumber: json['employeeNumber'] as String,
          name: json['name'] as String,
          email: json['email'] as String,
          role: json['role'] as String,
          department: json['department'] as String?,
          worksite: json['worksite'] == null
              ? null
              : WorksiteInfo.fromJson(_map(json['worksite'])));
  final String id;
  final String organizationId;
  final String employeeNumber;
  final String name;
  final String email;
  final String role;
  final String? department;
  final WorksiteInfo? worksite;
}

class WorksiteInfo {
  const WorksiteInfo(
      {required this.id,
      required this.name,
      required this.latitude,
      required this.longitude,
      required this.radiusMeters,
      required this.maxAccuracyMeters});
  factory WorksiteInfo.fromJson(Map<String, dynamic> json) => WorksiteInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num).toInt(),
      maxAccuracyMeters: (json['maxAccuracyMeters'] as num).toInt());
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final int maxAccuracyMeters;
}

class WorkShift {
  const WorkShift(
      {required this.dayOfWeek,
      required this.startMinute,
      required this.endMinute,
      required this.breakMinutes,
      required this.graceMinutes});
  factory WorkShift.fromJson(Map<String, dynamic> json) => WorkShift(
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      startMinute: (json['startMinute'] as num).toInt(),
      endMinute: (json['endMinute'] as num).toInt(),
      breakMinutes: (json['breakMinutes'] as num).toInt(),
      graceMinutes: (json['graceMinutes'] as num).toInt());
  final int dayOfWeek;
  final int startMinute;
  final int endMinute;
  final int breakMinutes;
  final int graceMinutes;
}

class HolidayInfo {
  const HolidayInfo(
      {required this.date, required this.name, required this.category});
  factory HolidayInfo.fromJson(Map<String, dynamic> json) => HolidayInfo(
      date: DateTime.parse(json['date'] as String).toLocal(),
      name: json['name'] as String,
      category: json['category'] as String);
  final DateTime date;
  final String name;
  final String category;
}

class AttendanceEventInfo {
  const AttendanceEventInfo(
      {required this.id,
      required this.kind,
      required this.capturedAt,
      required this.decision,
      required this.reasonCodes,
      this.distanceMeters});
  factory AttendanceEventInfo.fromJson(Map<String, dynamic> json) =>
      AttendanceEventInfo(
          id: json['id'] as String,
          kind: json['kind'] as String,
          capturedAt: DateTime.parse(json['capturedAt'] as String).toLocal(),
          decision: json['decision'] as String,
          reasonCodes:
              List<String>.from(json['reasonCodes'] as List? ?? const []),
          distanceMeters: _number(json['distanceMeters']));
  final String id;
  final String kind;
  final DateTime capturedAt;
  final String decision;
  final List<String> reasonCodes;
  final double? distanceMeters;
}

class AttendanceSummaryInfo {
  const AttendanceSummaryInfo(
      {required this.localDate,
      required this.workedMinutes,
      required this.breakMinutes,
      required this.lateMinutes,
      required this.undertimeMinutes,
      this.firstClockIn,
      this.lastClockOut});
  factory AttendanceSummaryInfo.fromJson(Map<String, dynamic> json) =>
      AttendanceSummaryInfo(
          localDate: DateTime.parse(json['localDate'] as String).toLocal(),
          workedMinutes: (json['workedMinutes'] as num).toInt(),
          breakMinutes: (json['breakMinutes'] as num).toInt(),
          lateMinutes: (json['lateMinutes'] as num).toInt(),
          undertimeMinutes: (json['undertimeMinutes'] as num).toInt(),
          firstClockIn: _date(json['firstClockIn']),
          lastClockOut: _date(json['lastClockOut']));
  final DateTime localDate;
  final DateTime? firstClockIn;
  final DateTime? lastClockOut;
  final int workedMinutes;
  final int breakMinutes;
  final int lateMinutes;
  final int undertimeMinutes;
}

class EmployeeRequest {
  const EmployeeRequest(
      {required this.id,
      required this.type,
      required this.status,
      required this.startsAt,
      required this.endsAt,
      required this.reason,
      required this.submittedAt});
  factory EmployeeRequest.fromJson(Map<String, dynamic> json) =>
      EmployeeRequest(
          id: json['id'] as String,
          type: json['type'] as String,
          status: json['status'] as String,
          startsAt: DateTime.parse(json['startsAt'] as String).toLocal(),
          endsAt: DateTime.parse(json['endsAt'] as String).toLocal(),
          reason: json['reason'] as String,
          submittedAt: DateTime.parse(json['submittedAt'] as String).toLocal());
  final String id;
  final String type;
  final String status;
  final DateTime startsAt;
  final DateTime endsAt;
  final String reason;
  final DateTime submittedAt;
}

class EmployeeNotification {
  const EmployeeNotification(
      {required this.id,
      required this.title,
      required this.body,
      required this.createdAt,
      this.readAt});
  factory EmployeeNotification.fromJson(Map<String, dynamic> json) =>
      EmployeeNotification(
          id: json['id'] as String,
          title: json['title'] as String,
          body: json['body'] as String,
          createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
          readAt: _date(json['readAt']));
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
}

class PayrollInfo {
  const PayrollInfo(
      {this.id,
      required this.periodStart,
      this.periodEnd,
      required this.status,
      required this.currency,
      required this.lines,
      required this.payslipAvailable});
  factory PayrollInfo.fromJson(Map<String, dynamic> json) => PayrollInfo(
      id: json['id'] as String?,
      periodStart: DateTime.parse(json['periodStart'] as String).toLocal(),
      periodEnd: _date(json['periodEnd']),
      status: json['status'] as String,
      currency: json['currency'] as String,
      lines: _list(json['lines']).map(PayrollLineInfo.fromJson).toList(),
      payslipAvailable: json['payslipAvailable'] as bool? ?? false);
  final String? id;
  final DateTime periodStart;
  final DateTime? periodEnd;
  final String status;
  final String currency;
  final List<PayrollLineInfo> lines;
  final bool payslipAvailable;
}

class PayrollLineInfo {
  const PayrollLineInfo(
      {required this.code,
      required this.description,
      required this.category,
      required this.amount});
  factory PayrollLineInfo.fromJson(Map<String, dynamic> json) =>
      PayrollLineInfo(
          code: json['code'] as String,
          description: json['description'] as String,
          category: json['category'] as String,
          amount: _number(json['amount']) ?? 0);
  final String code;
  final String description;
  final String category;
  final double amount;
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : <String, dynamic>{};
List<Map<String, dynamic>> _list(Object? value) =>
    value is List ? value.whereType<Map<String, dynamic>>().toList() : const [];
DateTime? _date(Object? value) =>
    value is String ? DateTime.parse(value).toLocal() : null;
double? _number(Object? value) => value is num
    ? value.toDouble()
    : value is String
        ? double.tryParse(value)
        : null;
