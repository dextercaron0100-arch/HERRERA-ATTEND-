export type AttendanceKind = 'CLOCK_IN' | 'BREAK_START' | 'BREAK_END' | 'CLOCK_OUT';
export type AttendanceDecision = 'ACCEPTED' | 'REJECTED' | 'REVIEW';
export interface ClockSubmission { employeeId:string; worksiteId:string; kind:AttendanceKind; capturedAt:string; latitude:number; longitude:number; accuracyMeters:number; idempotencyKey:string; deviceId:string }
export interface ClockResult { eventId:string; decision:AttendanceDecision; reasonCodes:string[]; distanceMeters:number }
