import { ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { CommentDto, CreateRequestDto, DecisionDto, DelegateDto } from './request.dto';
import { defaultApprovalRoles, nextRequestState } from './workflow';
import { Prisma } from '@prisma/client';
@Injectable() export class RequestsService {
  constructor(private readonly db:PrismaService){}
  async create(dto:CreateRequestDto){
    const employee=await this.db.employee.findUnique({where:{id:dto.employeeId}});
    if(!employee?.active) throw new NotFoundException('Active employee not found');
    const startsAt=new Date(dto.startsAt),endsAt=new Date(dto.endsAt);
    if(endsAt<=startsAt) throw new ConflictException('endsAt must be after startsAt');
    if(dto.type==='ATTENDANCE_CORRECTION'){
      const originalEventId=dto.evidence.originalEventId;
      const correctedKind=dto.evidence.correctedKind;
      if(typeof originalEventId!=='string'||!['CLOCK_IN','BREAK_START','BREAK_END','CLOCK_OUT'].includes(String(correctedKind))) throw new ConflictException('Corrections require evidence.originalEventId and evidence.correctedKind');
      const original=await this.db.attendanceEvent.findUnique({where:{id:originalEventId},include:{employee:true}});
      if(!original||original.employeeId!==employee.id) throw new ConflictException('Original event does not belong to this employee');
    }
    const policy=await this.db.approvalPolicy.findFirst({where:{organizationId:employee.organizationId,requestType:dto.type as any,active:true},orderBy:{createdAt:'desc'}});
    const roles=(policy?.steps as string[]|undefined)??defaultApprovalRoles(dto.type);
    if(!roles.length) throw new ConflictException('Approval policy has no steps');
    const request=await this.db.request.create({data:{organizationId:employee.organizationId,employeeId:employee.id,type:dto.type as any,startsAt,endsAt,reason:dto.reason,evidence:dto.evidence as Prisma.InputJsonValue,steps:{create:roles.map((approverRole,index)=>({sequence:index+1,approverRole:approverRole as any}))}},include:{steps:true,employee:true}});
    await Promise.all([this.notifyRole(employee.organizationId,roles[0],`New ${dto.type.toLowerCase().replaceAll('_',' ')} request`,`${employee.name} submitted a request.`,request.id),this.audit(employee.organizationId,employee.id,'REQUEST_SUBMITTED',request.id,{type:dto.type})]);
    return request;
  }
  list(filter:{organizationId?:string;employeeId?:string;status?:string}){return this.db.request.findMany({where:{organizationId:filter.organizationId,employeeId:filter.employeeId,status:filter.status as any},include:{employee:true,steps:true},orderBy:{submittedAt:'desc'}});}
  async get(id:string){const request=await this.db.request.findUnique({where:{id},include:{employee:true,steps:true,comments:{include:{author:true},orderBy:{createdAt:'asc'}}}});if(!request)throw new NotFoundException('Request not found');return request;}
  async decide(id:string,dto:DecisionDto){
    return this.db.$transaction(async tx=>{
      const request=await tx.request.findUnique({where:{id},include:{steps:true,employee:true}}); if(!request)throw new NotFoundException('Request not found'); if(request.status!=='PENDING')throw new ConflictException('Request is already decided');
      const actor=await tx.employee.findUnique({where:{id:dto.actorId}}); if(!actor||actor.organizationId!==request.organizationId)throw new ForbiddenException('Actor is outside this organization');
      const step=request.steps.find(s=>s.sequence===request.currentStep); if(!step)throw new ConflictException('Current approval step not found');
      if(step.delegatedToId!==actor.id&&step.approverId!==actor.id&&step.approverRole!==actor.role)throw new ForbiddenException(`This step requires ${step.approverRole}`);
      await tx.approvalStep.update({where:{id:step.id},data:{approverId:actor.id,decision:dto.decision,comment:dto.comment,decidedAt:new Date()}});
      const next=nextRequestState(dto.decision,request.currentStep,request.steps.length);
      const updated=await tx.request.update({where:{id},data:{status:next.status,currentStep:next.currentStep,decidedAt:next.complete?new Date():null},include:{steps:true,employee:true}});
      if(next.status==='APPROVED'&&request.type==='ATTENDANCE_CORRECTION'){
        const evidence=request.evidence as Record<string,unknown>; const originalEventId=String(evidence.originalEventId); const original=await tx.attendanceEvent.findUnique({where:{id:originalEventId}});
        if(!original)throw new ConflictException('Original correction event no longer exists');
        await tx.attendanceEvent.create({data:{employeeId:original.employeeId,worksiteId:original.worksiteId,kind:String(evidence.correctedKind) as any,capturedAt:typeof evidence.correctedAt==='string'?new Date(evidence.correctedAt):original.capturedAt,latitude:original.latitude,longitude:original.longitude,accuracyMeters:original.accuracyMeters,distanceMeters:original.distanceMeters,decision:'ACCEPTED',reasonCodes:['APPROVED_CORRECTION',`REQUEST:${id}`],idempotencyKey:`approved-correction:${id}`,deviceId:'APPROVAL_WORKFLOW',correctionOfId:original.id}});
      }
      await tx.auditLog.create({data:{organizationId:request.organizationId,actorId:actor.id,action:`REQUEST_${dto.decision}`,entityType:'Request',entityId:id,metadata:{step:step.sequence,comment:dto.comment??null}}});
      await tx.notification.create({data:{employeeId:request.employeeId,type:'REQUEST_STATUS',title:`Request ${next.status.toLowerCase()}`,body:next.complete?`Your ${request.type.toLowerCase().replaceAll('_',' ')} request is ${next.status.toLowerCase()}.`:'Your request advanced to the next approval step.',metadata:{requestId:id,status:next.status}}});
      if(!next.complete){const nextRole=request.steps.find(s=>s.sequence===next.currentStep)?.approverRole;const approvers=await tx.employee.findMany({where:{organizationId:request.organizationId,role:nextRole,active:true},select:{id:true}});if(approvers.length)await tx.notification.createMany({data:approvers.map(a=>({employeeId:a.id,type:'APPROVAL_REQUIRED',title:'Approval required',body:`${request.employee.name} has a request awaiting review.`,metadata:{requestId:id}}))});}
      return updated;
    });
  }
  async comment(id:string,dto:CommentDto){const request=await this.db.request.findUnique({where:{id}});const author=await this.db.employee.findUnique({where:{id:dto.authorId}});if(!request||!author)throw new NotFoundException();if(author.organizationId!==request.organizationId)throw new ForbiddenException();const comment=await this.db.requestComment.create({data:{requestId:id,authorId:author.id,body:dto.body}});await this.audit(request.organizationId,author.id,'REQUEST_COMMENTED',id,{});return comment;}
  async delegate(id:string,dto:DelegateDto){const request=await this.db.request.findUnique({where:{id},include:{steps:true}});if(!request||request.status!=='PENDING')throw new NotFoundException('Pending request not found');const [actor,delegate]=await Promise.all([this.db.employee.findUnique({where:{id:dto.actorId}}),this.db.employee.findUnique({where:{id:dto.delegateId}})]);const step=request.steps.find(s=>s.sequence===request.currentStep);if(!actor||!delegate||!step||actor.organizationId!==request.organizationId||delegate.organizationId!==request.organizationId)throw new ForbiddenException();if(actor.role!==step.approverRole&&step.approverId!==actor.id)throw new ForbiddenException('Only the current approver can delegate');const updated=await this.db.approvalStep.update({where:{id:step.id},data:{delegatedToId:delegate.id}});await Promise.all([this.db.notification.create({data:{employeeId:delegate.id,type:'APPROVAL_DELEGATED',title:'Approval delegated to you',body:'A request is awaiting your decision.',metadata:{requestId:id}}}),this.audit(request.organizationId,actor.id,'REQUEST_DELEGATED',id,{delegateId:delegate.id})]);return updated;}
  private async notifyRole(organizationId:string,role:string,title:string,body:string,requestId:string){const recipients=await this.db.employee.findMany({where:{organizationId,role:role as any,active:true},select:{id:true}});if(recipients.length)await this.db.notification.createMany({data:recipients.map(r=>({employeeId:r.id,type:'APPROVAL_REQUIRED',title,body,metadata:{requestId}}))});}
  private audit(organizationId:string,actorId:string,action:string,entityId:string,metadata:Record<string,unknown>){return this.db.auditLog.create({data:{organizationId,actorId,action,entityType:'Request',entityId,metadata:metadata as Prisma.InputJsonValue}});}
}
