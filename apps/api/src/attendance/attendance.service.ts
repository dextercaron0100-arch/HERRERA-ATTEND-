import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { ClockDto } from './clock.dto';
import { decideAttendance, distanceMeters } from './geofence';
import { CorrectionDto } from './correction.dto';
import { summarizeEvents } from './summary';
@Injectable() export class AttendanceService {
  constructor(private readonly db:PrismaService) {}
  async clock(dto:ClockDto){
    const prior=await this.db.attendanceEvent.findUnique({where:{idempotencyKey:dto.idempotencyKey}});
    if(prior) return this.result(prior);
    const [employee,worksite,device]=await Promise.all([this.db.employee.findUnique({where:{id:dto.employeeId}}),this.db.worksite.findUnique({where:{id:dto.worksiteId}}),this.db.registeredDevice.findFirst({where:{employeeId:dto.employeeId,deviceId:dto.deviceId,active:true,biometricsEnabled:true}})]);
    if(!employee?.active) throw new NotFoundException('Active employee not found');
    if(!device) throw new ConflictException('Attendance requires an active biometric-registered device');
    if(!worksite || employee.organizationId!==worksite.organizationId) throw new NotFoundException('Worksite not found');
    if(employee.worksiteId!==worksite.id) throw new ConflictException('Employee is not assigned to this worksite');
    const distance=distanceMeters(dto.latitude,dto.longitude,Number(worksite.latitude),Number(worksite.longitude));
    const outcome=decideAttendance(distance,worksite.radiusMeters,dto.accuracyMeters,worksite.maxAccuracyMeters);
    const event=await this.db.attendanceEvent.create({data:{...dto,capturedAt:new Date(dto.capturedAt),distanceMeters:distance,decision:outcome.decision,reasonCodes:outcome.reasonCodes}});
    return this.result(event);
  }
  async correct(dto:CorrectionDto){
    const prior=await this.db.attendanceEvent.findUnique({where:{idempotencyKey:dto.idempotencyKey}});
    if(prior) return this.result(prior);
    const original=await this.db.attendanceEvent.findUnique({where:{id:dto.originalEventId}});
    if(!original) throw new NotFoundException('Original attendance event not found');
    const correction=await this.db.attendanceEvent.create({data:{employeeId:original.employeeId,worksiteId:original.worksiteId,kind:dto.kind,capturedAt:original.capturedAt,latitude:original.latitude,longitude:original.longitude,accuracyMeters:original.accuracyMeters,distanceMeters:original.distanceMeters,decision:'ACCEPTED',reasonCodes:['APPROVED_CORRECTION',dto.reason],idempotencyKey:dto.idempotencyKey,deviceId:'ADMIN_CORRECTION',correctionOfId:original.id}});
    return this.result(correction);
  }
  async summarizeDay(employeeId:string,date:string){
    const start=new Date(`${date}T00:00:00.000Z`), end=new Date(start); end.setUTCDate(end.getUTCDate()+1);
    if(Number.isNaN(start.getTime())) throw new ConflictException('date must be YYYY-MM-DD');
    const events=await this.db.attendanceEvent.findMany({where:{employeeId,capturedAt:{gte:start,lt:end},decision:'ACCEPTED'},orderBy:{capturedAt:'asc'}});
    const result=summarizeEvents(events as any);
    const summary=await this.db.dailyAttendanceSummary.upsert({where:{employeeId_localDate:{employeeId,localDate:start}},create:{employeeId,localDate:start,firstClockIn:result.firstClockIn,lastClockOut:result.lastClockOut,workedMinutes:result.workedMinutes,breakMinutes:result.breakMinutes,sourceEventIds:result.sourceEventIds},update:{firstClockIn:result.firstClockIn,lastClockOut:result.lastClockOut,workedMinutes:result.workedMinutes,breakMinutes:result.breakMinutes,sourceEventIds:result.sourceEventIds,calculatedAt:new Date()}});
    if(result.missingPunch) await this.db.attendanceException.upsert({where:{id:`missing-${summary.id}`},create:{id:`missing-${summary.id}`,employeeId,summaryId:summary.id,type:'MISSING_PUNCH',reason:'Clock-in/out or break events are unmatched',evidence:{sourceEventIds:result.sourceEventIds}},update:{status:'OPEN',evidence:{sourceEventIds:result.sourceEventIds}}});
    if(events.some(e=>e.reasonCodes.includes('LOW_GPS_ACCURACY'))) await this.db.attendanceException.create({data:{employeeId,summaryId:summary.id,type:'LOCATION_REVIEW',reason:'One or more events require location review',evidence:{eventIds:events.filter(e=>e.reasonCodes.includes('LOW_GPS_ACCURACY')).map(e=>e.id)}}});
    return {...summary,missingPunch:result.missingPunch};
  }
  async listExceptions(organizationId:string,status:string){return this.db.attendanceException.findMany({where:{status:status as any,employee:{organizationId}},include:{employee:true,summary:true},orderBy:{createdAt:'desc'}});}
  async listSummaries(organizationId:string,date:string){
    const start=new Date(`${date}T00:00:00.000Z`),end=new Date(start);end.setUTCDate(end.getUTCDate()+1);
    if(!organizationId||Number.isNaN(start.getTime())) throw new ConflictException('organizationId and date are required');
    return this.db.dailyAttendanceSummary.findMany({where:{localDate:{gte:start,lt:end},employee:{organizationId,active:true}},include:{employee:{include:{worksite:true}}},orderBy:{employee:{name:'asc'}}});
  }
  async resolveException(id:string,actorId:string,status:'RESOLVED'|'DISMISSED'){
    const [exception,actor]=await Promise.all([this.db.attendanceException.findUnique({where:{id},include:{employee:true}}),this.db.employee.findUnique({where:{id:actorId}})]);
    if(!exception) throw new NotFoundException('Attendance exception not found');
    if(!actor||actor.organizationId!==exception.employee.organizationId||!['SUPERVISOR','HR','ADMIN'].includes(actor.role)) throw new ConflictException('Authorized attendance reviewer required');
    return this.db.$transaction(async tx=>{const updated=await tx.attendanceException.update({where:{id},data:{status,resolvedAt:new Date(),resolvedById:actor.id}});await tx.auditLog.create({data:{organizationId:actor.organizationId,actorId:actor.id,action:`ATTENDANCE_EXCEPTION_${status}`,entityType:'AttendanceException',entityId:id,metadata:{status}}});return updated;});
  }
  private result(event:any){return {eventId:event.id,decision:event.decision,reasonCodes:event.reasonCodes,distanceMeters:Number(event.distanceMeters)};}
}
